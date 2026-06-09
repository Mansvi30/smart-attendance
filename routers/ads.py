# New file: routers/ads.py
from fastapi import APIRouter, Depends
from models.dto import AdRequest
from services.ads_service import AdsService
from utils.helper import get_current_token

router = APIRouter()
ads_service = AdsService()

@router.post("/generate", dependencies=[Depends(get_current_token)])
async def generate_ad(ad_request: AdRequest):
    """
    Stream-generated radio ad script(s) based on the customer's requirements.
    The response is a streaming text response (SSE-like). If you need JSON variants,
    adapt AdsService.generate_ad_scripts to return structured JSON instead.
    """
    return await ads_service.generate_ad_scripts(ad_request)