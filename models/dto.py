# (full file with additions; based on original file with new DTOs for Ads)
from enum import Enum
from pydantic import BaseModel ,Field
from typing import List, Optional

class DeleteFilesDTO(BaseModel):
    namespace_id: str 
    ids: List[str] = None
    names:List[str] = None

class DeleteFileDTO(BaseModel):
    namespace_id: str 
    id:  str= None
    name: str = None    

class CreateBot(BaseModel): 
    bot_name:str   
    description:str 

class conversation(BaseModel): 
    question: str
    Ai_response: str  
    
class ChatRequest(BaseModel): 
    question: str
    namespace_id: str    
    chatHistory:List[conversation] 

class UserLogin(BaseModel):  
    email:str  
    password:str 


class Roles(str,Enum):
    SUPER_ADMIN = "SUPER_ADMIN"
    ADMIN = "ADMIN"
    KNOWLEDGE_OWNER = "KNOWLEDGE_OWNER" 
    
class UserRegister(BaseModel):  
    email:str  
    password:str  
    name:str  
    phone_number:int     
    company_name:str   
       
class UpdateUser(BaseModel):  
    _id:str
    email:str  
    name:str  
    phone_number:int     
    company_name:str 


class ResetPassword(BaseModel):  
    token:str  
    newPassword:str  
    confirmPassword:str    

class Status(str,Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"
   
class Product(str,Enum):
    KNOWLEDGE_MANAGER = "KNOWLEDGE_MANAGER" 


# -----------------------
# New DTOs for SpotBot Ads
# -----------------------
class AdRequest(BaseModel):
    product_name: str = Field(..., description="Name of the product or service")
    duration_seconds: Optional[int] = Field(30, description="Desired ad duration in seconds (approx.)")
    target_audience: Optional[str] = Field(None, description="Target audience / demographics")
    tone: Optional[str] = Field("informative", description="Tone of the ad (e.g., upbeat, humorous, serious)")
    key_messages: Optional[List[str]] = Field([], description="List of 1-5 key messages or bullet points to include")
    call_to_action: Optional[str] = Field("Visit our website", description="Primary call to action")
    language: Optional[str] = Field("English", description="Language for the script")
    num_variants: Optional[int] = Field(1, description="Number of script variants to generate")
    format: Optional[str] = Field("text", description="Return format: 'text' or 'ssml'")

class AdScript(BaseModel):
    variant_index: int
    script_text: str
    estimated_duration_seconds: Optional[int] = None
    ssml: Optional[str] = None

class AdResponse(BaseModel):
    scripts: List[AdScript]
    message: Optional[str] = "Ad scripts generated successfully"