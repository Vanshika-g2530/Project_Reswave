"""
RESWAVE - Domain Recommendation Engine
Section 4.3: Deterministic tag matching with proportional redistribution on skipped questions.
"""
from typing import List, Dict, Any, Tuple

DEFAULT_WEIGHTS = {
    "subjects": 0.30,
    "problems": 0.25,
    "workStyles": 0.20,
    "skills": 0.15,
    "goals": 0.10
}

def calculate_jaccard_overlap(user_tags: List[str], domain_tags: List[str]) -> float:
    if not user_tags or not domain_tags:
        return 0.0
    u_set = {t.strip().lower() for t in user_tags if t.strip().lower() not in ["not sure", "other", "skip"]}
    d_set = {t.strip().lower() for t in domain_tags}
    if not u_set:
        return 0.0
    intersection = u_set.intersection(d_set)
    return len(intersection) / len(u_set)

def score_domain_against_questionnaire(
    answers: Dict[str, Any], 
    domain: Dict[str, Any]
) -> Tuple[float, List[str]]:
    """
    Computes explainable score for a domain using the 5 weighted dimensions.
    Returns (score_out_of_100, list_of_reasons).
    """
    # Count answered questions
    answered_keys = []
    for k in ["subjects", "problems", "workStyles", "skills", "goals"]:
        val = answers.get(k, [])
        valid_items = [x for x in val if x and x.lower() not in ["not sure", "skip"]]
        if valid_items:
            answered_keys.append(k)
            
    # If fewer than 2 answered, return exploratory baseline (score = 50.0)
    if len(answered_keys) < 2:
        return 50.0, ["Broad exploratory suggestion based on foundational research areas"]

    # Proportional weight redistribution
    base_weight_sum = sum(DEFAULT_WEIGHTS[k] for k in answered_keys)
    normalized_weights = {k: DEFAULT_WEIGHTS[k] / base_weight_sum for k in answered_keys}

    reasons = []
    total_score = 0.0

    # 1. Subject Interest (30%)
    if "subjects" in answered_keys:
        subj_score = calculate_jaccard_overlap(answers.get("subjects", []), domain.get("subjectTags", []))
        total_score += subj_score * normalized_weights["subjects"]
        if subj_score > 0:
            matched = set(s.lower() for s in answers.get("subjects", [])).intersection(
                set(s.lower() for s in domain.get("subjectTags", []))
            )
            reasons.append(f"Matches your subject interest in {', '.join(matched).title()}")

    # 2. Problem Types (25%)
    if "problems" in answered_keys:
        prob_score = calculate_jaccard_overlap(answers.get("problems", []), domain.get("problemTags", []))
        total_score += prob_score * normalized_weights["problems"]
        if prob_score > 0:
            matched = set(s.lower() for s in answers.get("problems", [])).intersection(
                set(s.lower() for s in domain.get("problemTags", []))
            )
            reasons.append(f"Aligns with problems you want to address: {', '.join(matched).title()}")

    # 3. Work Styles (20%)
    if "workStyles" in answered_keys:
        style_score = calculate_jaccard_overlap(answers.get("workStyles", []), domain.get("workStyleTags", []))
        total_score += style_score * normalized_weights["workStyles"]
        if style_score > 0:
            matched = set(s.lower() for s in answers.get("workStyles", [])).intersection(
                set(s.lower() for s in domain.get("workStyleTags", []))
            )
            reasons.append(f"Involves your preferred work style: {', '.join(matched).title()}")

    # 4. Skills (15%)
    if "skills" in answered_keys:
        skill_score = calculate_jaccard_overlap(answers.get("skills", []), domain.get("skillTags", []))
        total_score += skill_score * normalized_weights["skills"]
        if skill_score > 0:
            matched = set(s.lower() for s in answers.get("skills", [])).intersection(
                set(s.lower() for s in domain.get("skillTags", []))
            )
            reasons.append(f"Applies skills you have or wish to develop: {', '.join(matched).title()}")

    # 5. Goal (10%)
    if "goals" in answered_keys:
        goal_score = calculate_jaccard_overlap(answers.get("goals", []), domain.get("goalTags", []))
        total_score += goal_score * normalized_weights["goals"]
        if goal_score > 0:
            reasons.append("Supports your declared academic & research milestone goals")

    # Optional topic in mind keyword boost
    topic_in_mind = answers.get("topicInMind", "")
    if topic_in_mind and len(topic_in_mind.strip()) > 2:
        words = [w.lower() for w in topic_in_mind.split() if len(w) > 3]
        domain_keywords = [k.lower() for k in domain.get("keywords", []) + domain.get("subdomains", [])]
        if any(w in " ".join(domain_keywords) for w in words):
            total_score = min(1.0, total_score + 0.1)
            reasons.append(f"Directly relates to your specific interest: '{topic_in_mind.strip()}'")

    final_score = round(total_score * 100, 1)
    if not reasons:
        reasons.append("Foundational interdisciplinary alignment with your profile")

    return final_score, reasons

def determine_fit_band(score: float, is_exploratory: bool = False) -> str:
    """
    Section 4.3: Display fit band: Strong / Possible / Explore.
    No decimal precision or career certainty claims.
    """
    if is_exploratory:
        return "Explore"
    if score >= 65.0:
        return "Strong"
    elif score >= 35.0:
        return "Possible"
    else:
        return "Explore"
