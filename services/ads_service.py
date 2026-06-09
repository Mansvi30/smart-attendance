# New file: services/ads_service.py
import os
from fastapi.responses import StreamingResponse
from typing import Generator, List
from langchain_mistralai import ChatMistralAI
from langchain_core.output_parsers import StrOutputParser
from models.dto import AdRequest, AdScript
from dotenv import load_dotenv
load_dotenv()

# Build LLM instance factory to avoid global state conflicts
def create_mistral_llm():
    return ChatMistralAI(
        mistral_api_key=os.getenv("MISTRAL_API_KEY"),
        model=os.getenv("MISTRAL_MODEL"),
        temperature=0.2
    )

class AdsService:
    def __init__(self):
        self.llm = create_mistral_llm()

    def _build_prompt(self, data: AdRequest, variant_index: int = 1) -> str:
        # Construct a detailed instruction prompt to generate a radio ad script
        key_msgs = "\n".join([f"- {m}" for m in data.key_messages]) if data.key_messages else "None provided"
        prompt = f"""
You are an expert copywriter who writes short, high-conversion radio ad scripts ("spots").
Constraints:
- Produce a concise script that fits approximately {data.duration_seconds} seconds.
- Use language: {data.language}
- Tone: {data.tone}
- The ad must include the product name: {data.product_name}
- Target audience: {data.target_audience or 'General Audience'}
- Key messages (one per line): {key_msgs}
- Call to action: {data.call_to_action}
- Produce 1 spot only for this variant. Do not produce multiple variants in a single completion.
- Provide a short estimated duration in seconds at the top in square brackets, e.g. [30s].
- If format is 'ssml', produce an SSML block after the script. Otherwise produce plain script text.

Variant: {variant_index}
Keep the language direct, vivid, and optimized for voice-only delivery. Use natural pacing notes or pauses like (pause) where helpful.
Begin output now.
"""
        return prompt.strip()

    def stream_ad_generation(self, ad_request: AdRequest) -> Generator[str, None, None]:
        """
        Streams the LLM output as text chunks. The router will return a StreamingResponse
        so the client can progressively display the ad script.
        """
        parser = StrOutputParser()
        for variant in range(1, max(1, ad_request.num_variants) + 1):
            prompt = self._build_prompt(ad_request, variant)
            chain = self.llm | parser
            # chain.stream yields chunks per pinecone_service pattern
            for chunk in chain.stream(prompt):
                # Include a simple separator between variants
                yield chunk
            # send a small separator between variants
            if ad_request.num_variants > 1 and variant < ad_request.num_variants:
                yield "\n\n--- End of Variant {} ---\n\n".format(variant)

    async def generate_ad_scripts(self, ad_request: AdRequest):
        """
        Returns a StreamingResponse (SSE-like) with the generated script content.
        If you prefer a non-streaming JSON response, you can adapt this method to collect
        the complete outputs and return structured JSON.
        """
        return StreamingResponse(self.stream_ad_generation(ad_request), media_type="text/event-stream")