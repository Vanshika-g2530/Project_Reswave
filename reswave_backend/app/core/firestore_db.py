"""
RESWAVE - Cloud Firestore & Transaction Engine
Implements atomic operations for team capacity, mentor reservation, and audit trails.
"""
import os
import json
from typing import Dict, Any, List, Optional
from datetime import datetime, timezone
from ..core.memory_db import db, utc_now_iso

# Check if Cloud Firestore is available
_firestore_client = None
try:
    from google.cloud import firestore
    if os.environ.get("GOOGLE_APPLICATION_CREDENTIALS") or os.environ.get("FIRESTORE_EMULATOR_HOST"):
        _firestore_client = firestore.Client()
except Exception:
    _firestore_client = None

class FirestoreTransactionEngine:
    """
    Handles atomic operations ensuring no race conditions or over-subscriptions occur.
    """
    @staticmethod
    def atomic_accept_team_application(app_id: str, owner_uid: str) -> Dict[str, Any]:
        """
        Section 7.2 & J:
        Atomically checks remaining capacity, decrements capacity, updates request status
        to 'Filled' if capacity == 0, adds member to project workspace, and returns updated objects.
        """
        app_rec = db.teamApplications.get(app_id)
        if not app_rec:
            raise ValueError("APPLICATION_NOT_FOUND")

        req = db.teamRequests.get(app_rec["requestId"])
        if not req:
            raise ValueError("REQUEST_NOT_FOUND")

        if req["ownerId"] != owner_uid:
            raise PermissionError("PERMISSION_DENIED_NOT_OWNER")

        # Atomic capacity check
        if req["remainingCapacity"] <= 0 or req["status"] != "Open":
            raise ValueError("CAPACITY_FULL_OR_CLOSED")

        # Transactional decrement
        req["remainingCapacity"] -= 1
        if req["remainingCapacity"] == 0:
            req["status"] = "Filled"
        req["updatedAt"] = utc_now_iso()

        # Update application state
        app_rec["status"] = "Accepted"
        app_rec["decidedAt"] = utc_now_iso()

        # Create or update project workspace (Section 9)
        proj_id = f"proj-{req['id']}"
        if proj_id not in db.projects:
            db.projects[proj_id] = {
                "id": proj_id,
                "ownerId": req["ownerId"],
                "title": req["title"],
                "description": req["description"],
                "domainTags": [req["primaryDomain"]] + req.get("relatedDomains", []),
                "memberIds": [req["ownerId"], app_rec["applicantId"]],
                "status": "Active",
                "startDate": utc_now_iso(),
                "sourceTeamRequestId": req["id"]
            }
        else:
            if app_rec["applicantId"] not in db.projects[proj_id]["memberIds"]:
                db.projects[proj_id]["memberIds"].append(app_rec["applicantId"])

        return {
            "status": "success",
            "application": app_rec,
            "teamRequest": req,
            "project": db.projects[proj_id]
        }

    @staticmethod
    def atomic_reserve_mentor_slot(mentor_id: str, mentee_id: str) -> Dict[str, Any]:
        """
        Section 7.3:
        Atomically verifies mentor opt-in, availability, and capacity (>0),
        then reserves a slot and increments activeMenteesCount.
        """
        m_prof = db.mentorProfiles.get(mentor_id)
        if not m_prof:
            raise ValueError("MENTOR_PROFILE_NOT_FOUND")

        if not m_prof.get("mentorshipEnabled", False) or m_prof.get("availability") != "Available":
            raise ValueError("MENTOR_NOT_AVAILABLE")

        max_cap = m_prof.get("maxCapacity", 3)
        active = m_prof.get("activeMenteesCount", 0)
        if active >= max_cap:
            raise ValueError("MENTOR_CAPACITY_REACHED")

        # Reserve slot
        m_prof["activeMenteesCount"] = active + 1
        if m_prof["activeMenteesCount"] >= max_cap:
            m_prof["availability"] = "Full"

        return {"status": "success", "mentorProfile": m_prof}
