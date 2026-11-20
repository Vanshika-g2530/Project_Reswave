"""
RESWAVE - Core Pydantic Schemas & Data Contracts
Implements all entities and contracts defined in Section 14 & 15.
"""
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime

# --- Enums / String Literals as Constrained Types ---

# Roles (Section 1.2 & 3.2 - Note: Admin is never in public signup)
# Student, PhD Scholar, Professor-Faculty, Researcher, Independent / Other, Admin / Moderator

class UserBase(BaseModel):
    email: EmailStr
    displayName: str = Field(..., min_length=2, max_length=80)
    role: str
    headline: Optional[str] = Field(None, max_length=120)
    bio: Optional[str] = Field(None, max_length=500)
    country: str
    city: Optional[str] = None
    institution: Optional[str] = None
    department: Optional[str] = None
    visibility: str = "Public to members"  # Public to members / Connections only / Private
    discoverable: bool = False
    preferredCollaborationMode: Optional[str] = "No preference"  # Remote / In-person / Hybrid / No preference
    notificationPreferences: Dict[str, bool] = Field(default_factory=lambda: {
        "connections": True,
        "teamRequests": True,
        "mentorship": True,
        "groups": True,
        "messages": True,
        "learningReminders": True,
        "wellbeingReminders": False
    })
    roleDetails: Dict[str, Any] = Field(default_factory=dict)

class UserCreate(UserBase):
    password: str = Field(..., min_length=8)
    termsAccepted: bool = True
    termsAcceptedVersion: str = "2.0"
    marketingConsent: bool = False

class UserResponse(UserBase):
    uid: str
    emailVerified: bool = False
    accountStatus: str = "active"  # active / suspended / pending_verification
    createdAt: str
    updatedAt: str

# --- Section 3.6: Multiple Research Interests ---
class ResearchInterestCreate(BaseModel):
    domainId: str
    subdomainId: str
    topicTags: List[str] = Field(..., min_items=1)
    keywords: List[str] = Field(default_factory=list)
    proficiency: str = "Beginner"  # Beginner / Intermediate / Advanced / Expert / Not sure
    status: str = "Exploring"      # Exploring / Learning / Active research / Completed / Published work
    skills: List[str] = Field(default_factory=list)
    methods: List[str] = Field(default_factory=list)
    goals: List[str] = Field(..., min_items=1)  # Learn / Find mentor / Find teammate / etc.
    availability: str = "Available"  # Available / Limited / Not available
    visibility: str = "Visible to members"  # Visible to members / Connections only / Hidden

class ResearchInterest(ResearchInterestCreate):
    id: str
    userId: str
    createdAt: str

# --- Section 4: Domain Taxonomy & Questionnaire ---
class DomainTaxonomy(BaseModel):
    id: str
    name: str
    parentId: Optional[str] = None
    shortDescription: str
    beginnerExplanation: str
    subdomains: List[str] = Field(default_factory=list)
    keywords: List[str] = Field(default_factory=list)
    subjectTags: List[str] = Field(default_factory=list)
    problemTags: List[str] = Field(default_factory=list)
    workStyleTags: List[str] = Field(default_factory=list)
    skillTags: List[str] = Field(default_factory=list)
    goalTags: List[str] = Field(default_factory=list)
    sampleResearchQuestions: List[str] = Field(default_factory=list)
    commonMethods: List[str] = Field(default_factory=list)
    learningResourceIds: List[str] = Field(default_factory=list)
    status: str = "Published"
    reviewedAt: str
    version: int = 1

class QuestionnaireInput(BaseModel):
    subjects: List[str] = Field(default_factory=list)
    problems: List[str] = Field(default_factory=list)
    workStyles: List[str] = Field(default_factory=list)
    skills: List[str] = Field(default_factory=list)
    experience: Optional[str] = "None"
    goals: List[str] = Field(default_factory=list)
    topicInMind: Optional[str] = Field(None, max_length=300)

class DomainRecommendation(BaseModel):
    domainId: str
    name: str
    fitBand: str  # Strong / Possible / Explore
    score: float
    reasons: List[str]
    sampleTopics: List[str]
    requiredSkills: List[str]
    sampleQuestions: List[str]
    beginnerResources: List[str]
    relatedGroups: List[str]

# --- Section 5: Research Learning Hub ---
class LearningResource(BaseModel):
    id: str
    title: str
    category: str
    domainTags: List[str] = Field(default_factory=list)
    level: str  # Beginner / Intermediate / Advanced
    format: str  # Article / Video / Checklist / External link
    summary: str
    contentOrUrl: str
    sourceName: str
    sourceUrl: str
    durationMinutes: int = 15
    prerequisites: List[str] = Field(default_factory=list)
    authorOrEditor: str
    reviewedDate: str
    nextReviewDate: str
    status: str = "Published"  # Draft / Review / Published / Archived

class ResourceProgress(BaseModel):
    id: str
    userId: str
    resourceId: str
    status: str = "Not started"  # Not started / In progress / Completed
    saved: bool = False
    privateNotes: Optional[str] = None
    completedAt: Optional[str] = None
    updatedAt: str

# --- Section 6: Publications & Paper Library ---
class Publication(BaseModel):
    id: str
    userId: str
    title: str = Field(..., min_length=5, max_length=300)
    authors: List[str] = Field(default_factory=list)
    type: str  # Journal article / Conference paper / Preprint / Poster / Book chapter / Other
    venue: Optional[str] = None
    year: Optional[int] = None
    doi: Optional[str] = None
    url: Optional[str] = None
    abstract: Optional[str] = Field(None, max_length=2000)
    visibility: str = "Public to members"  # Public to members / Connections / Private

class PaperLibraryItem(BaseModel):
    id: str
    userId: str
    title: str = Field(..., min_length=1)
    authors: List[str] = Field(default_factory=list)
    doi: Optional[str] = None
    url: Optional[str] = None
    abstract: Optional[str] = None
    year: Optional[int] = None
    tags: List[str] = Field(default_factory=list)
    readingStatus: str = "Want to read"  # Want to read / Reading / Read
    privateNotes: Optional[str] = None  # Strictly private to user
    createdAt: str
    updatedAt: str

# --- Section 7: Team Requests, Applications & Projects ---
class SkillRequirement(BaseModel):
    skill: str
    mustHave: bool = True

class TeamRequestCreate(BaseModel):
    title: str = Field(..., min_length=5, max_length=100)
    description: str = Field(..., min_length=50, max_length=2000)
    primaryDomain: str
    relatedDomains: List[str] = Field(default_factory=list)
    topics: List[str] = Field(..., min_items=1)
    skillsNeeded: List[SkillRequirement] = Field(..., min_items=1)
    rolesNeeded: List[str] = Field(..., min_items=1)
    membersNeeded: int = Field(..., ge=1, le=10)
    experiencePref: str = "Any"  # Beginner-friendly / Intermediate / Advanced / Any
    commitment: str = "Flexible"  # One-time / 1–4 weeks / 1–3 months / 3+ months / Flexible
    mode: str = "Remote"  # Remote / In-person / Hybrid
    location: Optional[str] = None
    startDate: Optional[str] = None
    applicationQuestions: List[str] = Field(default_factory=list, max_items=3)
    visibility: str = "Discoverable"  # Discoverable / Unlisted

class TeamRequest(TeamRequestCreate):
    id: str
    ownerId: str
    remainingCapacity: int
    status: str = "Open"  # Open / Paused / Filled / Closed
    createdAt: str
    updatedAt: str

class TeamApplicationCreate(BaseModel):
    answers: List[str] = Field(default_factory=list)

class TeamApplication(BaseModel):
    id: str
    requestId: str
    applicantId: str
    answers: List[str]
    status: str = "Pending"  # Pending / Accepted / Declined / Clarification
    createdAt: str
    decidedAt: Optional[str] = None

class Project(BaseModel):
    id: str
    ownerId: str
    title: str
    description: str
    domainTags: List[str]
    memberIds: List[str]
    status: str = "Active"  # Planning / Active / On hold / Completed / Closed
    startDate: Optional[str] = None
    targetDate: Optional[str] = None
    sourceTeamRequestId: Optional[str] = None

class ProjectTask(BaseModel):
    id: str
    projectId: str
    title: str
    description: Optional[str] = None
    assigneeId: Optional[str] = None
    priority: str = "Medium"  # Low / Medium / High
    dueDate: Optional[str] = None
    status: str = "Not started"  # Not started / In progress / Done

class ProjectMilestone(BaseModel):
    id: str
    projectId: str
    title: str
    description: Optional[str] = None
    dueDate: Optional[str] = None
    assignedMembers: List[str] = Field(default_factory=list)
    status: str = "Pending"

# --- Section 7.3: Mentorship ---
class MentorProfile(BaseModel):
    userId: str
    mentorshipEnabled: bool = True
    expertiseTags: List[str]
    helpTypes: List[str]
    menteeLevels: List[str]
    formats: List[str]
    availability: str = "Available"  # Available / Paused / Full
    maxCapacity: int = 3
    activeMenteesCount: int = 0
    preferredFrequency: Optional[str] = "Bi-weekly"
    timezone: Optional[str] = "UTC"
    visibility: str = "Public to members"

class MentorRequestCreate(BaseModel):
    mentorId: str
    interestId: str
    helpType: str
    context: str = Field(..., min_length=20, max_length=1000)
    format: str = "Remote"
    frequency: str = "Bi-weekly"
    timezone: str = "UTC"
    questions: Optional[str] = None
    consentShareProfile: bool = True

class MentorRequest(MentorRequestCreate):
    id: str
    menteeId: str
    status: str = "Pending"  # Pending / Accepted / Declined / Clarification
    createdAt: str

# --- Section 8: Groups & Feed ---
class Group(BaseModel):
    id: str
    ownerId: str
    title: str = Field(..., min_length=3, max_length=80)
    description: str = Field(..., max_length=1000)
    primaryDomain: str
    topics: List[str]
    purpose: str
    membershipMode: str = "Open"  # Open / Request to join / Invite-only
    visibility: str = "Discoverable"  # Discoverable / Unlisted
    rules: str = Field(..., max_length=1000)
    moderators: List[str] = Field(default_factory=list)
    coverImageUrl: Optional[str] = None
    status: str = "Active"
    createdAt: str

class FeedPostCreate(BaseModel):
    text: str = Field(..., min_length=1, max_length=3000)
    postType: str = "Research update"  # Research update / Question / Paper share / Project update / Opportunity shared / General academic discussion
    domainTags: List[str] = Field(default_factory=list)
    attachmentUrl: Optional[str] = None
    audience: str = "Members"  # Members / Selected group / Project members
    groupId: Optional[str] = None
    projectId: Optional[str] = None
    commentsEnabled: bool = True

class FeedPost(FeedPostCreate):
    id: str
    authorId: str
    authorName: str
    authorHeadline: Optional[str] = None
    createdAt: str
    reactionCount: int = 0
    commentCount: int = 0

# --- Section 10: Well-Being & Peer Support ---
class MoodCheckinCreate(BaseModel):
    mood: str  # Calm / Good / Motivated / Okay / Stressed / Overwhelmed / Low / Anxious / Prefer not to say
    factors: List[str] = Field(default_factory=list)
    intensity: Optional[int] = Field(None, ge=1, le=5)  # Self-rating 1-5; explicitly non-clinical
    helpfulAction: Optional[str] = None
    privateNote: Optional[str] = Field(None, max_length=1000)

class MoodEntry(MoodCheckinCreate):
    id: str
    userId: str
    createdAt: str

class PeerSupportPostCreate(BaseModel):
    category: str  # Research stress / Publication rejection / Motivation / Work-life balance / PhD life / First-time researcher / Other
    text: str = Field(..., min_length=10, max_length=2000)
    displayMode: str = "Show profile name"  # Show profile name / Hide identity from ordinary members
    groupId: Optional[str] = None
    commentsEnabled: bool = True
    safetyAcknowledged: bool = Field(..., description="Must acknowledge peer support is not clinical therapy")

class PeerSupportPost(PeerSupportPostCreate):
    id: str
    authorId: str
    authorDisplayName: str  # Filtered dynamically to 'Anonymous Member' for ordinary members if displayMode == Hide identity
    createdAt: str

# --- Section 11: Academic Listings & Opportunities ---
class Opportunity(BaseModel):
    id: str
    type: str  # Conference / Workshop / Webinar / Fellowship / Internship / Grant / Call for Papers / Other
    title: str
    organiser: str
    description: str
    tags: List[str]
    startDate: Optional[str] = None
    endDate: Optional[str] = None
    submissionDeadline: Optional[str] = None
    mode: str = "Online"  # Online / In-person / Hybrid
    location: Optional[str] = None
    eligibility: str = "Open (check official source)"
    officialSourceUrl: str
    registrationUrl: Optional[str] = None
    lastVerifiedDate: str  # Mandatory provenance
    status: str = "Published"  # Draft / Published / Expired / Withdrawn
    reviewedBy: Optional[str] = None

# --- Section 12: Notifications ---
class NotificationItem(BaseModel):
    id: str
    recipientId: str
    type: str
    title: str
    body: str
    targetType: Optional[str] = None
    targetId: Optional[str] = None
    read: bool = False
    createdAt: str

# --- Section 13: Moderation Reports ---
class ModerationReportCreate(BaseModel):
    targetType: str  # post / user / group / comment / opportunity
    targetId: str
    reason: str  # harassment / bullying / harmful advice / personal information / spam / crisis concern / other
    note: Optional[str] = None

class ModerationReport(ModerationReportCreate):
    id: str
    reporterId: str
    status: str = "Under Review"  # Under Review / Resolved / Dismissed
    actionTaken: Optional[str] = None
    assignedModerator: Optional[str] = None
    createdAt: str
    updatedAt: str

# --- Section 6: My Network (Connections, Followers, Following) ---
class ConnectionRequestCreate(BaseModel):
    note: Optional[str] = Field(None, max_length=300)

class ConnectionRequestResponse(BaseModel):
    id: str
    senderId: str
    senderName: str
    senderRole: Optional[str] = None
    senderInstitution: Optional[str] = None
    receiverId: str
    receiverName: str
    receiverRole: Optional[str] = None
    receiverInstitution: Optional[str] = None
    status: str = "PENDING"  # PENDING / ACCEPTED / DECLINED / WITHDRAWN
    note: Optional[str] = None
    createdAt: str
    updatedAt: str

class NetworkSummaryResponse(BaseModel):
    connectionsCount: int = 0
    followersCount: int = 0
    followingCount: int = 0
    pendingReceivedCount: int = 0

# --- Section 8.2: Find a Mentor Questionnaire & Lifecycle ---
class MentorQuestionnaireInput(BaseModel):
    helpType: str
    researchArea: List[str] = Field(default_factory=list)
    academicLevel: str
    currentStage: str
    desiredOutcome: str
    preferredFormat: str
    frequency: str
    duration: str
    availability: str
    additionalContext: Optional[str] = None

class MentorDecisionRequest(BaseModel):
    status: str  # ACCEPTED / DECLINED / NEEDS_INFO
    reason: Optional[str] = None

# --- Feed & Social Interactions ---
class CommentCreate(BaseModel):
    text: str = Field(..., min_length=1, max_length=1000)

class CommentResponse(BaseModel):
    id: str
    postId: str
    authorId: str
    authorName: str
    authorRole: Optional[str] = None
    text: str
    createdAt: str

# --- Direct Messaging ---
class SendMessageRequest(BaseModel):
    recipientId: Optional[str] = None
    text: str = Field(..., min_length=1, max_length=3000)
    attachmentUrl: Optional[str] = None

class MessageResponse(BaseModel):
    id: str
    conversationId: str
    senderId: str
    senderName: str
    text: str
    attachmentUrl: Optional[str] = None
    createdAt: str
    read: bool = False

class ConversationResponse(BaseModel):
    id: str
    participants: List[str]
    otherUserId: str
    otherUserName: str
    otherUserRole: Optional[str] = None
    otherUserInstitution: Optional[str] = None
    lastMessage: Optional[str] = None
    lastMessageTime: Optional[str] = None
    unreadCount: int = 0

# --- Groups & Projects Creation ---
class GroupCreate(BaseModel):
    title: str = Field(..., min_length=3, max_length=80)
    description: str = Field(..., max_length=1000)
    primaryDomain: str
    topics: List[str] = Field(default_factory=list)
    purpose: str = "Research collaboration and discussion"
    membershipMode: str = "Open"  # Open / Request to join / Invite-only
    visibility: str = "Discoverable"
    rules: str = "Be constructive, respect copyright, uphold academic integrity."

class ProjectTaskCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=150)
    description: Optional[str] = None
    assigneeId: Optional[str] = None
    priority: str = "Medium"
    dueDate: Optional[str] = None

class ProjectMilestoneCreate(BaseModel):
    title: str = Field(..., min_length=2, max_length=150)
    description: Optional[str] = None
    dueDate: Optional[str] = None

class FCMTokenRequest(BaseModel):
    token: str
    deviceInfo: Optional[str] = None

