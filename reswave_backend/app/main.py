"""
RESWAVE - Canonical FastAPI Mobile Backend Service
Version 3.0 | Cloud Run & Local Development API
"""
import uuid
from typing import List, Dict, Any, Optional
from fastapi import FastAPI, HTTPException, Header, Depends, Query, status
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from .core.memory_db import db, utc_now_iso
from .core.firestore_db import FirestoreTransactionEngine
from .services.security import verify_bearer_token, require_admin
from .models.schemas import (
    UserCreate, UserResponse,
    ResearchInterestCreate, ResearchInterest,
    QuestionnaireInput, DomainRecommendation,
    TeamRequestCreate, TeamRequest, TeamApplicationCreate, TeamApplication,
    MoodCheckinCreate, MoodEntry, PeerSupportPostCreate, PeerSupportPost,
    PaperLibraryItem, Publication, LearningResource, Opportunity,
    ModerationReportCreate, ModerationReport
)
from .services.domain_finder import score_domain_against_questionnaire, determine_fit_band
from .services.matching_engine import (
    score_researcher_match,
    score_teammate_for_request,
    score_mentor_match,
    score_group_recommendation
)
from .services.seed_data import EMERGENCY_SUPPORT_RESOURCES

app = FastAPI(
    title="ResWave Mobile API Service",
    version="3.0.0",
    description="Academic Research Journey & Community Application Backend"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==================== Health ====================
@app.get("/health")
def health_check():
    return {"status": "ok", "service": "reswave-mobile-api", "version": "3.0.0"}

# ==================== Auth & Profile ====================
class LoginRequest(BaseModel):
    email: str
    password: str

@app.post("/v1/auth/signup")
def signup(data: UserCreate):
    for u in db.users.values():
        if u["email"].lower() == data.email.lower():
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="EMAIL_ALREADY_EXISTS")
    
    if data.role in ["Admin", "Admin / Moderator"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="CANNOT_SELF_ASSIGN_ADMIN")

    uid = f"usr-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    user_record = {
        "uid": uid,
        "email": data.email.lower(),
        "displayName": data.displayName.strip(),
        "role": data.role,
        "headline": data.headline,
        "bio": data.bio,
        "country": data.country,
        "city": data.city,
        "institution": data.institution,
        "department": data.department,
        "visibility": data.visibility,
        "discoverable": data.discoverable,
        "preferredCollaborationMode": data.preferredCollaborationMode,
        "notificationPreferences": data.notificationPreferences,
        "roleDetails": data.roleDetails,
        "termsAccepted": data.termsAccepted,
        "termsAcceptedVersion": "3.0",
        "termsAcceptedAt": now,
        "emailVerified": False,
        "accountStatus": "active",
        "isAdmin": False,
        "createdAt": now,
        "updatedAt": now
    }
    db.users[uid] = user_record
    return {"status": "success", "user": user_record, "token": uid}

@app.post("/v1/auth/login")
def login(data: LoginRequest):
    for u in db.users.values():
        if u["email"].lower() == data.email.lower():
            if u.get("accountStatus") == "suspended":
                raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="ACCOUNT_SUSPENDED")
            return {"status": "success", "user": u, "token": u["uid"]}
    raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="INVALID_CREDENTIALS")

@app.post("/v1/auth/verify-email")
def verify_email(user: Dict[str, Any] = Depends(verify_bearer_token)):
    u_rec = db.users.get(user["uid"])
    if u_rec:
        u_rec["emailVerified"] = True
        u_rec["updatedAt"] = utc_now_iso()
    return {"status": "success", "emailVerified": True}

@app.get("/v1/users/me")
def get_my_profile(user: Dict[str, Any] = Depends(verify_bearer_token)):
    u_rec = db.users.get(user["uid"])
    if not u_rec:
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
    return u_rec

@app.put("/v1/users/me")
def update_my_profile(updates: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    u_rec = db.users.get(user["uid"])
    if not u_rec:
        raise HTTPException(status_code=404, detail="USER_NOT_FOUND")
    for key in ["uid", "email", "isAdmin", "createdAt"]:
        updates.pop(key, None)
    if "role" in updates and updates["role"] in ["Admin", "Admin / Moderator"]:
        updates.pop("role")
    u_rec.update(updates)
    u_rec["updatedAt"] = utc_now_iso()
    return u_rec

# ==================== Multi-Domain Research Interests (Section 3.6) ====================
@app.get("/v1/users/me/interests")
def get_my_interests(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [i for i in db.researchInterests.values() if i["userId"] == user["uid"]]

@app.post("/v1/users/me/interests")
def add_research_interest(interest: ResearchInterestCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    int_id = f"int-{uuid.uuid4().hex[:8]}"
    rec = {
        "id": int_id,
        "userId": user["uid"],
        **interest.dict(),
        "createdAt": utc_now_iso()
    }
    db.researchInterests[int_id] = rec
    return rec

@app.put("/v1/users/me/interests/{int_id}")
def update_research_interest(int_id: str, updates: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.researchInterests.get(int_id)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="INTEREST_NOT_FOUND")
    for key in ["id", "userId", "createdAt"]:
        updates.pop(key, None)
    rec.update(updates)
    return rec

@app.delete("/v1/users/me/interests/{int_id}")
def delete_research_interest(int_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.researchInterests.get(int_id)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="INTEREST_NOT_FOUND")
    del db.researchInterests[int_id]
    return {"status": "deleted", "id": int_id}

# ==================== Research Domain Finder (Section 4) ====================
@app.get("/v1/domains")
def list_domains():
    return list(db.domains.values())

@app.post("/v1/domain-recommendations")
def get_domain_recommendations(answers: QuestionnaireInput):
    ans_dict = answers.dict()
    valid_dims = 0
    for k in ["subjects", "problems", "workStyles", "skills", "goals"]:
        v = [x for x in ans_dict.get(k, []) if x and x.lower() not in ["not sure", "skip"]]
        if v:
            valid_dims += 1
    is_exploratory = (valid_dims < 2)
    results = []

    for d in db.domains.values():
        if d.get("status") != "Published":
            continue
        score, reasons = score_domain_against_questionnaire(ans_dict, d)
        fit_band = determine_fit_band(score, is_exploratory)
        res_titles = [r["title"] for r in db.learningResources.values() if r.get("id") in d.get("learningResourceIds", [])]

        results.append({
            "domainId": d["id"],
            "name": d["name"],
            "fitBand": fit_band,
            "score": score if not is_exploratory else 50.0,
            "reasons": reasons,
            "sampleTopics": d.get("subdomains", []),
            "requiredSkills": d.get("skillTags", []),
            "sampleQuestions": d.get("sampleResearchQuestions", []),
            "beginnerResources": res_titles,
            "relatedGroups": [g["title"] for g in db.groups.values() if g.get("primaryDomain") == d["id"]]
        })

    if not is_exploratory:
        results.sort(key=lambda x: x["score"], reverse=True)
    return results

# ==================== Learning Hub (Section 5) ====================
@app.get("/v1/learning/resources")
def list_learning_resources(
    domain: Optional[str] = None,
    level: Optional[str] = None,
    format: Optional[str] = None,
    query: Optional[str] = None
):
    items = [r for r in db.learningResources.values() if r.get("status") == "Published"]
    if domain:
        items = [r for r in items if any(domain.lower() in t.lower() for t in r.get("domainTags", []))]
    if level:
        items = [r for r in items if r.get("level", "").lower() == level.lower()]
    if format:
        items = [r for r in items if r.get("format", "").lower() == format.lower()]
    if query:
        q = query.lower()
        items = [r for r in items if q in r.get("title", "").lower() or q in r.get("summary", "").lower()]
    return items

@app.get("/v1/learning/progress/{res_id}")
def get_resource_progress(res_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    prog_id = f"{user['uid']}_{res_id}"
    prog = db.resourceProgress.get(prog_id)
    if not prog:
        return {"resourceId": res_id, "status": "Not started", "saved": False, "privateNotes": None}
    return prog

@app.post("/v1/learning/progress/{res_id}")
def update_resource_progress(res_id: str, payload: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    prog_id = f"{user['uid']}_{res_id}"
    prog = db.resourceProgress.get(prog_id, {
        "id": prog_id,
        "userId": user["uid"],
        "resourceId": res_id,
        "status": "Not started",
        "saved": False,
        "privateNotes": None,
        "completedAt": None
    })
    if "status" in payload:
        prog["status"] = payload["status"]
        if payload["status"] == "Completed":
            prog["completedAt"] = utc_now_iso()
    if "saved" in payload:
        prog["saved"] = payload["saved"]
    if "privateNotes" in payload:
        prog["privateNotes"] = payload["privateNotes"]
    prog["updatedAt"] = utc_now_iso()
    db.resourceProgress[prog_id] = prog
    return prog

# ==================== Personal Paper Library (Section 6.3) ====================
@app.get("/v1/papers")
def list_my_papers(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [p for p in db.paperLibrary.values() if p["userId"] == user["uid"]]

@app.post("/v1/papers")
def add_paper(payload: Dict[str, Any], user: Dict[str, Any] = Depends(verify_bearer_token)):
    title = payload.get("title", "").strip()
    if not title:
        raise HTTPException(status_code=400, detail="TITLE_REQUIRED")
    pid = f"paper-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    rec = {
        "id": pid,
        "userId": user["uid"],
        "title": title,
        "authors": payload.get("authors", []),
        "doi": payload.get("doi"),
        "url": payload.get("url"),
        "abstract": payload.get("abstract"),
        "year": payload.get("year"),
        "tags": payload.get("tags", []),
        "readingStatus": payload.get("readingStatus", "Want to read"),
        "privateNotes": payload.get("privateNotes"), # Strictly owner-only
        "createdAt": now,
        "updatedAt": now
    }
    db.paperLibrary[pid] = rec
    return rec

@app.delete("/v1/papers/{pid}")
def delete_paper(pid: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.paperLibrary.get(pid)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="PAPER_NOT_FOUND")
    del db.paperLibrary[pid]
    return {"status": "deleted", "id": pid}

# ==================== Smart Matching & Semantic Recommendations (Section 7 & G) ====================
@app.get("/v1/matches/researchers")
def match_researchers(
    domainId: Optional[str] = None,
    topics: Optional[str] = None,
    mode: Optional[str] = "No preference",
    user: Dict[str, Any] = Depends(verify_bearer_token)
):
    query_topics = [t.strip() for t in topics.split(",")] if topics else []
    query_criteria = {
        "domainId": domainId,
        "topicTags": query_topics,
        "preferredCollaborationMode": mode
    }
    results = []
    for cand_uid, cand_user in db.users.items():
        if cand_uid == user["uid"]:
            continue
        cand_interests = [i for i in db.researchInterests.values() if i["userId"] == cand_uid]
        score, reasons = score_researcher_match(query_criteria, cand_user, cand_interests)
        if score > 0:
            results.append({
                "userId": cand_uid,
                "displayName": cand_user["displayName"],
                "role": cand_user["role"],
                "institution": cand_user.get("institution"),
                "headline": cand_user.get("headline"),
                "score": score,
                "fitBand": "Strong" if score >= 65 else ("Possible" if score >= 35 else "Explore"),
                "reasons": reasons,
                "interests": cand_interests
            })
    results.sort(key=lambda x: x["score"], reverse=True)
    return results

@app.get("/v1/matches/mentors")
def match_mentors(
    topics: Optional[str] = None,
    helpType: Optional[str] = None,
    level: Optional[str] = "Beginner",
    user: Dict[str, Any] = Depends(verify_bearer_token)
):
    topic_list = [t.strip() for t in topics.split(",")] if topics else []
    needs = {"topics": topic_list, "helpType": helpType, "currentLevel": level}
    results = []
    for m_uid, m_prof in db.mentorProfiles.items():
        m_user = db.users.get(m_uid)
        if not m_user:
            continue
        score, reasons, eligible = score_mentor_match(needs, m_prof, m_user)
        if eligible and score > 0:
            results.append({
                "mentorId": m_uid,
                "displayName": m_user["displayName"],
                "headline": m_user.get("headline"),
                "institution": m_user.get("institution"),
                "expertise": m_prof.get("expertiseTags", []),
                "helpTypes": m_prof.get("helpTypes", []),
                "remainingCapacity": m_prof.get("maxCapacity", 3) - m_prof.get("activeMenteesCount", 0),
                "score": score,
                "reasons": reasons
            })
    results.sort(key=lambda x: x["score"], reverse=True)
    return results

# ==================== Team Requests & Atomic Capacity Management (Section 7.2) ====================
@app.get("/v1/team-requests")
def list_team_requests(domain: Optional[str] = None):
    reqs = [r for r in db.teamRequests.values() if r.get("visibility") == "Discoverable"]
    if domain:
        reqs = [r for r in reqs if r.get("primaryDomain") == domain or domain in r.get("relatedDomains", [])]
    return reqs

@app.post("/v1/team-requests")
def create_team_request(data: TeamRequestCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    req_id = f"req-{uuid.uuid4().hex[:8]}"
    now = utc_now_iso()
    rec = {
        "id": req_id,
        "ownerId": user["uid"],
        "remainingCapacity": data.membersNeeded,
        "status": "Open",
        "createdAt": now,
        "updatedAt": now,
        **data.dict()
    }
    db.teamRequests[req_id] = rec
    return rec

@app.post("/v1/team-requests/{req_id}/apply")
def apply_to_team_request(req_id: str, data: TeamApplicationCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    team_req = db.teamRequests.get(req_id)
    if not team_req:
        raise HTTPException(status_code=404, detail="REQUEST_NOT_FOUND")
    if team_req["status"] != "Open" or team_req["remainingCapacity"] <= 0:
        raise HTTPException(status_code=400, detail="TEAM_REQUEST_NOT_OPEN")
    if team_req["ownerId"] == user["uid"]:
        raise HTTPException(status_code=400, detail="CANNOT_APPLY_TO_OWN_REQUEST")

    for app in db.teamApplications.values():
        if app["requestId"] == req_id and app["applicantId"] == user["uid"]:
            raise HTTPException(status_code=409, detail="DUPLICATE_APPLICATION")

    app_id = f"app-{uuid.uuid4().hex[:8]}"
    u_rec = db.users.get(user["uid"], {})
    rec = {
        "id": app_id,
        "requestId": req_id,
        "applicantId": user["uid"],
        "applicantName": u_rec.get("displayName", "Applicant"),
        "answers": data.answers,
        "status": "Pending",
        "createdAt": utc_now_iso(),
        "decidedAt": None
    }
    db.teamApplications[app_id] = rec
    return rec

@app.post("/v1/team-applications/{app_id}/decision")
def decide_team_application(app_id: str, decision: Dict[str, str], user: Dict[str, Any] = Depends(verify_bearer_token)):
    new_status = decision.get("status")
    if new_status == "Accepted":
        try:
            return FirestoreTransactionEngine.atomic_accept_team_application(app_id, user["uid"])
        except ValueError as ve:
            raise HTTPException(status_code=409, detail=str(ve))
        except PermissionError as pe:
            raise HTTPException(status_code=403, detail=str(pe))
    else:
        app_rec = db.teamApplications.get(app_id)
        if not app_rec:
            raise HTTPException(status_code=404, detail="APPLICATION_NOT_FOUND")
        app_rec["status"] = new_status
        app_rec["decidedAt"] = utc_now_iso()
        return {"status": "success", "application": app_rec}

# ==================== Collaboration Workspace & Tasks (Section 9) ====================
@app.get("/v1/projects")
def list_my_projects(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [p for p in db.projects.values() if user["uid"] in p.get("memberIds", []) or p["ownerId"] == user["uid"]]

@app.get("/v1/projects/{proj_id}")
def get_project_details(proj_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    proj = db.projects.get(proj_id)
    if not proj or (user["uid"] not in proj.get("memberIds", []) and proj["ownerId"] != user["uid"] and not user.get("isAdmin")):
        raise HTTPException(status_code=403, detail="PERMISSION_DENIED_NOT_PROJECT_MEMBER")
    tasks = [t for t in db.tasks.values() if t.get("projectId") == proj_id]
    milestones = [m for m in db.milestones.values() if m.get("projectId") == proj_id]
    return {"project": proj, "tasks": tasks, "milestones": milestones}

# ==================== Well-Being (Section 10 - Strictly Confidential Mood) ====================
@app.get("/v1/wellbeing/moods")
def list_my_mood_entries(user: Dict[str, Any] = Depends(verify_bearer_token)):
    # Owner-only access (Section 10.1)
    return [m for m in db.moodEntries.values() if m["userId"] == user["uid"]]

@app.post("/v1/wellbeing/moods")
def record_mood_checkin(data: MoodCheckinCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    mid = f"mood-{uuid.uuid4().hex[:8]}"
    rec = {
        "id": mid,
        "userId": user["uid"],
        "createdAt": utc_now_iso(),
        **data.dict()
    }
    db.moodEntries[mid] = rec
    return rec

@app.delete("/v1/wellbeing/moods/{mid}")
def delete_mood_entry(mid: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rec = db.moodEntries.get(mid)
    if not rec or rec["userId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="ENTRY_NOT_FOUND")
    del db.moodEntries[mid]
    return {"status": "deleted", "id": mid}

@app.get("/v1/wellbeing/support-posts")
def list_support_posts(user: Dict[str, Any] = Depends(verify_bearer_token)):
    posts = list(db.supportPosts.values())
    is_admin = user.get("isAdmin", False)
    clean_posts = []
    for p in posts:
        item = dict(p)
        if item.get("displayMode") == "Hide identity from ordinary members" and not is_admin and item.get("authorId") != user["uid"]:
            item["authorDisplayName"] = "Anonymous Member"
        clean_posts.append(item)
    return clean_posts

@app.post("/v1/wellbeing/support-posts")
def create_support_post(data: PeerSupportPostCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    if not data.safetyAcknowledged:
        raise HTTPException(status_code=400, detail="SAFETY_ACKNOWLEDGEMENT_REQUIRED")
    sp_id = f"sp-{uuid.uuid4().hex[:8]}"
    u_rec = db.users.get(user["uid"], {})
    rec = {
        "id": sp_id,
        "authorId": user["uid"],
        "authorDisplayName": u_rec.get("displayName", "Member"),
        "createdAt": utc_now_iso(),
        **data.dict()
    }
    db.supportPosts[sp_id] = rec
    return rec

@app.get("/v1/wellbeing/emergency-resources")
def get_emergency_resources():
    return EMERGENCY_SUPPORT_RESOURCES

# ==================== Academic Opportunities (Section 11) ====================
@app.get("/v1/opportunities")
def list_opportunities(type: Optional[str] = None, mode: Optional[str] = None):
    items = [o for o in db.opportunities.values() if o.get("status") == "Published"]
    if type:
        items = [o for o in items if o.get("type", "").lower() == type.lower()]
    if mode:
        items = [o for o in items if o.get("mode", "").lower() == mode.lower()]
    return items

# ==================== Notifications (Section 12) ====================
@app.get("/v1/notifications")
def list_my_notifications(user: Dict[str, Any] = Depends(verify_bearer_token)):
    return [n for n in db.notifications.values() if n["recipientId"] == user["uid"]]

@app.post("/v1/notifications/{notif_id}/read")
def mark_notification_read(notif_id: str, user: Dict[str, Any] = Depends(verify_bearer_token)):
    n = db.notifications.get(notif_id)
    if not n or n["recipientId"] != user["uid"]:
        raise HTTPException(status_code=404, detail="NOTIFICATION_NOT_FOUND")
    n["read"] = True
    return n

# ==================== Mobile Admin & Platform Governance (Section 13) ====================
@app.post("/v1/reports")
def submit_report(data: ModerationReportCreate, user: Dict[str, Any] = Depends(verify_bearer_token)):
    rid = f"rep-{uuid.uuid4().hex[:8]}"
    rec = {
        "id": rid,
        "reporterId": user["uid"],
        "status": "Under Review",
        "createdAt": utc_now_iso(),
        "updatedAt": utc_now_iso(),
        **data.dict()
    }
    db.reports[rid] = rec
    return rec

@app.get("/v1/admin/reports")
def admin_list_reports(admin: Dict[str, Any] = Depends(require_admin)):
    return list(db.reports.values())

@app.get("/v1/admin/analytics")
def admin_analytics(admin: Dict[str, Any] = Depends(require_admin)):
    # Aggregates active users, completion, matches, requests - EXCLUDES MOOD CONTENT (Section 13)
    return {
        "totalUsers": len(db.users),
        "totalProjects": len(db.projects),
        "totalTeamRequests": len(db.teamRequests),
        "totalLearningResources": len(db.learningResources),
        "totalOpportunities": len(db.opportunities),
        "openReportsCount": len([r for r in db.reports.values() if r["status"] == "Under Review"])
    }
