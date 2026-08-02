import re
import os

vocab_path = '/Users/dulorai/olitun/olitunapp/lib/shared/providers/seeders/vocab_seeder.dart'
sentence_path = '/Users/dulorai/olitun/olitunapp/lib/shared/providers/seeders/sentence_seeder.dart'

# ── PROGRESSION STAGES ──────────────────────────────────────────────────────
# Categorize lessons into hidden character progression stages
PROGRESSION = {
    # Vocabulary lessons
    'lesson_vocab_basics': 'beginner',
    'lesson_vocab_family': 'beginner',
    'lesson_vocab_colors': 'beginner',
    'lesson_vocab_nature': 'beginner',
    'lesson_vocab_daily': 'growth',
    'lesson_vocab_time': 'growth',
    'lesson_vocab_trending': 'growth',
    'lesson_vocab_idioms_beginner': 'beginner',
    'lesson_vocab_idioms_intermediate': 'growth',
    'lesson_vocab_idioms_advanced': 'advanced',
    'lesson_vocab_conversational_1': 'future',
    'lesson_vocab_conversational_2': 'future',
    'lesson_vocab_folk_1': 'advanced',
    'lesson_vocab_folk_2': 'advanced',
    # Sentence lessons
    'lesson_sentences_basics': 'beginner',
    'lesson_sentences_conversations': 'growth',
    'lesson_sentences_polite': 'beginner',
    'lesson_sentences_time_weather': 'growth',
    'lesson_sentences_complex_beginner': 'growth',
    'lesson_sentences_complex_intermediate': 'advanced',
    'lesson_sentences_complex_advanced': 'advanced',
    'lesson_sentences_conversational_1': 'future',
    'lesson_sentences_conversational_2': 'future',
    'lesson_sentences_conversational_3': 'future',
    'lesson_sentences_folk_1': 'advanced',
    'lesson_sentences_folk_2': 'advanced',
    'lesson_sentences_folk_3': 'advanced',
}

# ── SPEAKER AND DIALOGUE STAGING ───────────────────────────────────────────
def is_olitun_speaker(meaning, index):
    meaning_l = meaning.lower()
    if '?' in meaning_l or 'how' in meaning_l or 'what' in meaning_l or 'where' in meaning_l or 'who' in meaning_l or 'why' in meaning_l or 'when' in meaning_l or 'can you' in meaning_l:
        return True
    if meaning_l.startswith('i ') or meaning_l.startswith('my ') or meaning_l.startswith('yes') or meaning_l.startswith('no,') or meaning_l.startswith('we will') or 'hungry' in meaning_l:
        return False
    return index % 2 == 0

# ── MEMORABLE SCENE GENERATOR ──────────────────────────────────────────────
def generate_scenic_image_direction(meaning, stage, speaker_desc, dialogue_rule, index):
    meaning_l = meaning.lower()
    
    # 1. Colors
    if 'red' in meaning_l:
        return f"{speaker_desc} holds a ripe, bright red pomegranate, showing its rich color with a proud and happy smile.{dialogue_rule}"
    elif 'yellow' in meaning_l:
        return f"{speaker_desc} holds up a bright yellow sunflower, smiling warmly under the bright sunlight of the field.{dialogue_rule}"
    elif 'green' in meaning_l and 'leaf' in meaning_l:
        return f"{speaker_desc} compares two different shades of green leaves, looking closely with curious eyes.{dialogue_rule}"
    elif 'green' in meaning_l:
        return f"{speaker_desc} stands in a lush green rice field, looking around with arms spread wide, feeling connected to the earth.{dialogue_rule}"
    elif 'white' in meaning_l:
        return f"{speaker_desc} points happily to a pristine white jasmine flower blooming on a green bush in the garden.{dialogue_rule}"
    elif 'black' in meaning_l and 'charcoal' in meaning_l:
        return f"{speaker_desc} holding a piece of black charcoal, sketching a clean drawing on a stone tablet with focus.{dialogue_rule}"
    elif 'black' in meaning_l:
        return f"{speaker_desc} looks at a glossy black obsidian stone found near the stream, holding it up to catch the light with wonder.{dialogue_rule}"
    elif 'blue' in meaning_l and 'sky' in meaning_l:
        return f"{speaker_desc} sits on a grassy hill, looking up at the vast sky-blue horizon with a hopeful expression.{dialogue_rule}"
    elif 'blue' in meaning_l:
        return f"{speaker_desc} points to the deep blue sky dotted with fluffy white clouds, eyes shining with curiosity.{dialogue_rule}"
    elif 'golden' in meaning_l or 'silk' in meaning_l:
        return f"{speaker_desc} admires a strand of golden raw silk thread, holding it up to watch it shimmer in the sun.{dialogue_rule}"
    elif 'brown' in meaning_l or 'mud' in meaning_l:
        return f"{speaker_desc} works with rich brown clay, sculpting a small toy pot with focused, creative hands.{dialogue_rule}"
    elif 'pink' in meaning_l:
        return f"{speaker_desc} holding a soft pink lotus flower gently, smiling at its beautiful petals.{dialogue_rule}"
    elif 'purple' in meaning_l or 'eggplant' in meaning_l:
        return f"{speaker_desc} harvesting a ripe, glossy purple eggplant from the garden, looking proud of the yield.{dialogue_rule}"
    elif 'silver' in meaning_l or 'moon' in meaning_l:
        return f"{speaker_desc} points up at the bright silver crescent moon in the night sky, eyes filled with wonder.{dialogue_rule}"
    elif 'orange' in meaning_l or 'fire' in meaning_l:
        return f"{speaker_desc} looking at a crackling orange campfire, warm light reflecting on a happy, peaceful face.{dialogue_rule}"
    elif 'shiny' in meaning_l or 'bright' in meaning_l:
        return f"{speaker_desc} holding a shiny, polished brass plate that reflects the morning sunlight with brilliant rays.{dialogue_rule}"
    elif 'mixed' in meaning_l:
        return f"{speaker_desc} mixing different colored clay on a wooden board, laughing with creative excitement.{dialogue_rule}"
    elif 'grey' in meaning_l or 'gray' in meaning_l:
        return f"{speaker_desc} looking at a smooth grey river pebble, feeling its texture with a curious, calm expression.{dialogue_rule}"
        
    # 2. Family
    if 'father' in meaning_l:
        return f"A kind, tall Santhal father and {speaker_desc} standing side-by-side, sharing a warm moment as they look over a project.{dialogue_rule}"
    elif 'mother' in meaning_l:
        return f"A gentle Santhal mother smiling warmly as she helps {speaker_desc} adjust a neat shoulder bag.{dialogue_rule}"
    elif 'elder brother' in meaning_l:
        return f"An older brother pointing toward the hills, explaining the weather patterns to {speaker_desc} with a confident smile.{dialogue_rule}"
    elif 'elder sister' in meaning_l:
        return f"{speaker_desc} and an older sister reading a storybook together, both looking at the pages with shared focus.{dialogue_rule}"
    elif 'younger brother' in meaning_l:
        return f"{speaker_desc} gently guiding a younger brother by the hand, pointing out a colorful butterfly in the garden.{dialogue_rule}"
    elif 'younger sister' in meaning_l:
        return f"{speaker_desc} sitting beside a younger sister, helping her write a word on a clean sand board with pride.{dialogue_rule}"
    elif 'grandfather' in meaning_l:
        return f"{speaker_desc} sitting on a traditional cot, listening with wide eyes to an elder grandfather who is telling a legend.{dialogue_rule}"
    elif 'grandmother' in meaning_l:
        return f"{speaker_desc} sitting beside an elder grandmother who is showing how to weave a neat basket, sharing a warm smile.{dialogue_rule}"
    elif 'uncle' in meaning_l:
        return f"{speaker_desc} watching with interest as a kind uncle tunes a traditional stringed banam instrument.{dialogue_rule}"
    elif 'aunt' in meaning_l:
        return f"{speaker_desc} helping an aunt decorate a village home's wall with traditional geometric patterns.{dialogue_rule}"
    elif 'spouse' in meaning_l or 'family' in meaning_l:
        return f"{speaker_desc} standing proudly with a family member in front of a neat, decorated village home.{dialogue_rule}"

    # 3. Nature & Environment
    if 'water' in meaning_l:
        return f"{speaker_desc} drinking cool, clean water from a traditional clay pot, looking refreshed and happy.{dialogue_rule}"
    elif 'river' in meaning_l or 'stream' in meaning_l:
        return f"{speaker_desc} discovering a clear, flowing spring in the forest, pointing at the clean water.{dialogue_rule}"
    elif 'tree' in meaning_l or 'forest' in meaning_l:
        return f"{speaker_desc} planting a young green seedling in rich soil, showing care and responsibility for nature.{dialogue_rule}"
    elif 'flower' in meaning_l or 'blossom' in meaning_l:
        return f"{speaker_desc} holding a vibrant wild flower, smelling its scent with a happy, relaxed expression.{dialogue_rule}"
    elif 'leaf' in meaning_l or 'leaves' in meaning_l:
        return f"{speaker_desc} collecting fallen autumn leaves in a basket, helping to clean the yard with a smile.{dialogue_rule}"
    elif 'sun' in meaning_l or 'bong' in meaning_l or 'deity' in meaning_l:
        return f"{speaker_desc} looking up at the warm morning sun rising over the hills, eyes filled with hope.{dialogue_rule}"
    elif 'star' in meaning_l:
        return f"{speaker_desc} lying on a straw mat under a clear night sky, pointing at a shooting star in wonder.{dialogue_rule}"
    elif 'rain' in meaning_l:
        return f"{speaker_desc} standing under a shelter, watching fresh raindrops fall on green leaves, smiling with curiosity.{dialogue_rule}"
    elif 'soil' in meaning_l or 'earth' in meaning_l or 'clay' in meaning_l:
        return f"{speaker_desc} holding a handful of rich, dark soil, ready to plant seeds, looking hopeful and proud.{dialogue_rule}"

    # 4. Modern, Tech, Future
    if 'tablet' in meaning_l or 'screen' in meaning_l or 'computer' in meaning_l or 'tech' in meaning_l:
        return f"{speaker_desc} typing on a bright tablet screen showing educational graphics, eyes glowing with curiosity.{dialogue_rule}"
    elif 'phone' in meaning_l or 'mobile' in meaning_l:
        return f"{speaker_desc} showing a mobile screen with a language learning app to a friend, smiling with confidence.{dialogue_rule}"
    elif 'business' in meaning_l or 'market' in meaning_l or 'shop' in meaning_l:
        return f"{speaker_desc} showcasing a handcrafted basket they made, proud to present their creation at the market.{dialogue_rule}"
    elif 'future' in meaning_l or 'success' in meaning_l or 'ambition' in meaning_l:
        return f"{speaker_desc} looking forward toward a modern skyline in the distance, eyes filled with determination and hope.{dialogue_rule}"
    elif 'online' in meaning_l or 'internet' in meaning_l:
        return f"{speaker_desc} happily showing a connection signal icon on a tablet screen, expressing excitement for online learning.{dialogue_rule}"

    # 5. Idioms / Wisdom
    if 'wisdom' in meaning_l or 'truth' in meaning_l or 'proverb' in meaning_l:
        return f"{speaker_desc} standing tall on a hill overlooking the village, looking forward with strong resolution.{dialogue_rule}"
    elif 'judge' in meaning_l or 'right' in meaning_l:
        return f"{speaker_desc} pointing toward a balanced, hand-carved wooden scale, indicating fairness and justice.{dialogue_rule}"

    # 6. Actions, School, Objects
    if 'book' in meaning_l or 'read' in meaning_l or 'study' in meaning_l:
        return f"{speaker_desc} excitedly discovering knowledge inside a large, open picture book that glows with colorful patterns.{dialogue_rule}"
    elif 'friend' in meaning_l or 'companion' in meaning_l:
        return f"{speaker_desc} smiling warmly while pointing happily toward the learner, conveying friendship and belonging.{dialogue_rule}"
    elif 'school' in meaning_l or 'class' in meaning_l:
        return f"{speaker_desc} standing proudly in front of a bright, clean school building, gesturing toward the entrance.{dialogue_rule}"
    elif 'work' in meaning_l or 'job' in meaning_l or 'task' in meaning_l:
        return f"{speaker_desc} carefully carrying out a task, like neatly filing books or designing a wooden model.{dialogue_rule}"
    elif 'idea' in meaning_l or 'create' in meaning_l or 'invent' in meaning_l:
        return f"{speaker_desc} with a bright lightbulb icon appearing above them, looking upward with a spark of creativity.{dialogue_rule}"
    elif 'play' in meaning_l or 'game' in meaning_l:
        return f"{speaker_desc} laughing and running while balancing a spinning toy disk on a stick, feeling joyful.{dialogue_rule}"
    elif 'music' in meaning_l or 'drum' in meaning_l or 'sing' in meaning_l:
        return f"{speaker_desc} playing a traditional hand-drum (tumdak) with an energetic, rhythmic posture and a wide smile.{dialogue_rule}"
    elif 'dance' in meaning_l:
        return f"{speaker_desc} performing a graceful, traditional dance movement, arms extended with elegance and joy.{dialogue_rule}"
    elif 'write' in meaning_l or 'letter' in meaning_l:
        return f"{speaker_desc} writing clean Ol Chiki characters on a blackboard with chalk, standing tall with confidence.{dialogue_rule}"

    # Fallbacks based on Stage - varied dynamically to avoid repetition
    if stage == 'beginner':
        fallbacks = [
            f"{speaker_desc} walks along a winding path in the beautiful green village, pointing with curiosity toward the horizon.{dialogue_rule}",
            f"{speaker_desc} sits peacefully under a large shady tree, looking out over the village with a happy smile.{dialogue_rule}",
            f"{speaker_desc} stands beside a traditional home, pointing happily at a colorful detail on the hand-painted wall.{dialogue_rule}",
            f"{speaker_desc} kneels in a patch of wild flowers, looking at the colorful petals with curiosity.{dialogue_rule}",
        ]
        return fallbacks[index % len(fallbacks)]
    elif stage == 'growth':
        fallbacks = [
            f"{speaker_desc} proudly holds a hand-painted wooden sign, smiling warmly with confidence.{dialogue_rule}",
            f"{speaker_desc} points to a chalkboard showing simple diagrams, looking encouragingly toward classmates.{dialogue_rule}",
            f"{speaker_desc} works carefully on a drawing page spread out on a wooden table, focused and happy.{dialogue_rule}",
            f"{speaker_desc} stands tall in a schoolyard, holding a new notebook and smiling with pride.{dialogue_rule}",
        ]
        return fallbacks[index % len(fallbacks)]
    elif stage == 'advanced':
        fallbacks = [
            f"{speaker_desc} stands with hands on hips, looking out over the village from a scenic hill, representing leadership.{dialogue_rule}",
            f"{speaker_desc} gestures toward a village map drawn on a board, explaining a plan to classmates with confidence.{dialogue_rule}",
            f"{speaker_desc} sits in a circle with friends around a small fire, gesturing warmly while sharing a traditional story.{dialogue_rule}",
            f"{speaker_desc} stands proudly at a crossroads in the village, pointing toward a path of opportunity.{dialogue_rule}",
        ]
        return fallbacks[index % len(fallbacks)]
    else:  # future
        fallbacks = [
            f"{speaker_desc} stands beside a modern work table with drafting papers and a digital tablet, pointing forward with hope.{dialogue_rule}",
            f"{speaker_desc} stands in a clean, modern learning space, gesturing toward a screen showing village success metrics.{dialogue_rule}",
            f"{speaker_desc} stands under the bright sun, showcasing a creative blueprint of a village development project with pride.{dialogue_rule}",
            f"{speaker_desc} works together with classmates around a table filled with building blocks and tablets, smiling with ambition.{dialogue_rule}",
        ]
        return fallbacks[index % len(fallbacks)]


def get_body_language_and_learning_moment(emotion, speaker_desc):
    if emotion == 'Curiosity':
        return (
            "Eyes wide with wonder, body leaning forward, pointing with an inquisitive finger.",
            f"{speaker_desc} demonstrating active observation and a love for finding out new things."
        )
    elif emotion == 'Friendship':
        return (
            "Warm direct eye contact, relaxed shoulders, open arms in a welcoming gesture.",
            f"{speaker_desc} showing warmth, inclusion, and building a strong social bond."
        )
    elif emotion == 'Confidence':
        return (
            "Standing tall, head held high, chest slightly out, a bright and self-assured smile.",
            f"{speaker_desc} exhibiting self-reliance, readiness to learn, and pride in their capabilities."
        )
    elif emotion == 'Kindness':
        return (
            "Gentle smile, soft eyes, hands offering help or gesturing politely with care.",
            f"{speaker_desc} putting empathy into action, helping classmates or respecting elders."
        )
    elif emotion == 'Gratitude':
        return (
            "Slightly bowed head, hands held together or offering a token of appreciation, warm smile.",
            f"{speaker_desc} acknowledging and appreciating the kindness and efforts of others."
        )
    elif emotion == 'Responsibility':
        return (
            "Focused and attentive expression, steady hands working carefully, steady stance.",
            f"{speaker_desc} taking charge of duties, caring for the environment or community."
        )
    elif emotion == 'Leadership':
        return (
            "Upright posture, chin slightly raised, confident hand gestures guiding attention forward.",
            f"{speaker_desc} taking initiative, guiding others, and showing vision for the future."
        )
    elif emotion == 'Creativity':
        return (
            "Eyes shining with a spark of ideas, head tilted thoughtfully, holding a creative tool.",
            f"{speaker_desc} showing innovative thinking, artistic expression, or puzzle-solving."
        )
    elif emotion == 'Problem Solving':
        return (
            "Determined expression, hand on chin or inspecting detail closely, look of concentration.",
            f"{speaker_desc} overcoming a challenge, figuring out how things work with logic."
        )
    elif emotion == 'Hope':
        return (
            "Looking upward and forward, eyes shining bright with positive expectation, smiling gently.",
            f"{speaker_desc} expressing optimism for progress, new opportunities, and future success."
        )
    elif emotion == 'Ambition':
        return (
            "Determined forward-looking gaze, confident stance, finger pointing toward the distant horizon.",
            f"{speaker_desc} aiming high, showing aspiration for modern education and career path."
        )
    elif emotion == 'Pride':
        return (
            "Standing proud and tall, head high, shoulders back, holding cultural artifacts or projects.",
            f"{speaker_desc} celebrating cultural identity, heritage, and personal achievements."
        )
    elif emotion == 'Achievement':
        return (
            "Cheerful smile, hands raised in a small celebration or showing a finished project.",
            f"{speaker_desc} enjoying the reward of dedication, effort, and hard work."
        )
    else:
        return (
            "Expressive facial features, energetic pose, looking forward with confidence.",
            f"{speaker_desc} making a connection between the word meaning and positive growth."
        )

# ── METADATA AND SCENE GENERATOR ───────────────────────────────────────────
def generate_block_data(lesson_id, clean_latin, clean_ol, meaning, index, is_sentence=False):
    stage = PROGRESSION.get(lesson_id, 'growth')
    meaning_l = meaning.lower()
    
    # 1. Staging & Speakers
    if is_sentence:
        speaker_is_olitun = is_olitun_speaker(meaning, index)
        speaker_desc = "Olitun" if speaker_is_olitun else "a young Santhal child classmate"
        dialogue_rule = " Show only the speaking character, never show both speakers in the same frame."
    else:
        speaker_is_olitun = True
        speaker_desc = "Olitun"
        dialogue_rule = ""

    # 2. Character Progression-based Themes
    if stage == 'beginner':
        emotions_pool = ['Curiosity', 'Friendship', 'Kindness']
        growth_pool = ['Communication', 'Confidence', 'Learning']
        goals_pool = ['Make a new friend', 'Learn something new', 'Explore nature']
        
        emotion = emotions_pool[index % len(emotions_pool)]
        growth_value = growth_pool[index % len(growth_pool)]
        character_goal = goals_pool[index % len(goals_pool)]
        
        if 'hello' in meaning_l or 'greet' in meaning_l or 'welcome' in meaning_l:
            emotion, growth_value, character_goal = 'Friendship', 'Communication', 'Make a new friend'
        elif 'water' in meaning_l or 'nature' in meaning_l or 'tree' in meaning_l or 'river' in meaning_l or 'star' in meaning_l or 'flower' in meaning_l:
            emotion, growth_value, character_goal = 'Curiosity', 'Learning', 'Explore nature'

    elif stage == 'growth':
        emotions_pool = ['Confidence', 'Gratitude', 'Responsibility']
        growth_pool = ['Learning', 'Confidence', 'Responsibility']
        goals_pool = ['Complete a task', 'Practice communication', 'Build confidence', 'Help someone']
        
        emotion = emotions_pool[index % len(emotions_pool)]
        growth_value = growth_pool[index % len(growth_pool)]
        character_goal = goals_pool[index % len(goals_pool)]
        
        if 'work' in meaning_l or 'study' in meaning_l or 'read' in meaning_l or 'write' in meaning_l or 'school' in meaning_l or 'book' in meaning_l:
            emotion, growth_value, character_goal = 'Confidence', 'Learning', 'Build confidence'
        elif 'help' in meaning_l or 'please' in meaning_l or 'give' in meaning_l or 'wait' in meaning_l or 'share' in meaning_l:
            emotion, growth_value, character_goal = 'Gratitude', 'Responsibility', 'Help someone'

    elif stage == 'advanced':
        emotions_pool = ['Pride', 'Achievement', 'Gratitude']
        growth_pool = ['Leadership', 'Creativity', 'Problem Solving']
        goals_pool = ['Solve a problem', 'Teach others', 'Create something useful']
        
        emotion = emotions_pool[index % len(emotions_pool)]
        growth_value = growth_pool[index % len(growth_pool)]
        character_goal = goals_pool[index % len(goals_pool)]
        
        if 'wisdom' in meaning_l or 'truth' in meaning_l or 'proverb' in meaning_l or 'judge' in meaning_l or 'elder' in meaning_l or 'right' in meaning_l:
            emotion, growth_value, character_goal = 'Pride', 'Leadership', 'Teach others'
        elif 'create' in meaning_l or 'make' in meaning_l or 'play' in meaning_l or 'dance' in meaning_l or 'music' in meaning_l or 'drum' in meaning_l:
            emotion, growth_value, character_goal = 'Achievement', 'Creativity', 'Create something useful'

    else:  # future
        emotions_pool = ['Hope', 'Ambition', 'Pride']
        growth_pool = ['Technology', 'Entrepreneurship', 'Leadership']
        goals_pool = ['Create something useful', 'Learn something new', 'Build confidence']
        
        emotion = emotions_pool[index % len(emotions_pool)]
        growth_value = growth_pool[index % len(growth_pool)]
        character_goal = goals_pool[index % len(goals_pool)]
        
        if 'tech' in meaning_l or 'computer' in meaning_l or 'online' in meaning_l or 'phone' in meaning_l or 'tablet' in meaning_l or 'screen' in meaning_l or 'internet' in meaning_l:
            emotion, growth_value, character_goal = 'Hope', 'Technology', 'Learn something new'
        elif 'business' in meaning_l or 'market' in meaning_l or 'sell' in meaning_l or 'success' in meaning_l or 'future' in meaning_l or 'money' in meaning_l or 'cost' in meaning_l:
            emotion, growth_value, character_goal = 'Ambition', 'Entrepreneurship', 'Build confidence'

    # Determine story arc dynamically
    if stage == 'beginner':
        story_arcs_pool = ['Making New Friend', 'Exploring Village', 'Exploring Nature']
        story_arc = story_arcs_pool[index % len(story_arcs_pool)]
        if 'hello' in meaning_l or 'greet' in meaning_l or 'welcome' in meaning_l:
            story_arc = 'Making New Friend'
        elif 'water' in meaning_l or 'nature' in meaning_l or 'tree' in meaning_l or 'river' in meaning_l:
            story_arc = 'Exploring Nature'
    elif stage == 'growth':
        story_arcs_pool = ['Learning New Things', 'Helping Others', 'Building Confidence']
        story_arc = story_arcs_pool[index % len(story_arcs_pool)]
        if 'work' in meaning_l or 'study' in meaning_l or 'read' in meaning_l or 'write' in meaning_l or 'school' in meaning_l:
            story_arc = 'Learning New Things'
        elif 'help' in meaning_l or 'please' in meaning_l or 'give' in meaning_l:
            story_arc = 'Helping Others'
    elif stage == 'advanced':
        story_arcs_pool = ['Working Together', 'Exploring Nature', 'Dreaming Big']
        story_arc = story_arcs_pool[index % len(story_arcs_pool)]
        if 'wisdom' in meaning_l or 'truth' in meaning_l or 'proverb' in meaning_l:
            story_arc = 'Dreaming Big'
        elif 'create' in meaning_l or 'make' in meaning_l or 'play' in meaning_l or 'dance' in meaning_l:
            story_arc = 'Working Together'
    else:  # future
        story_arcs_pool = ['Modern World', 'Technology & Learning', 'Future Success']
        story_arc = story_arcs_pool[index % len(story_arcs_pool)]
        if 'tech' in meaning_l or 'computer' in meaning_l or 'online' in meaning_l or 'phone' in meaning_l:
            story_arc = 'Technology & Learning'
        elif 'business' in meaning_l or 'market' in meaning_l or 'sell' in meaning_l:
            story_arc = 'Future Success'

    # 3. Overrides for vocabulary representations (visual understanding over literal translation)
    vocab_visual_overrides = {
        'book': ('Olitun excitedly discovering knowledge inside a large, open picture book that glows slightly with colorful learning patterns.', 'Curiosity', 'Learn something new'),
        'friend': ('Olitun smiling warmly while pointing happily toward the learner, conveying a deep feeling of friendship and belonging.', 'Friendship', 'Make a new friend'),
        'school': ('Olitun standing proudly in front of a bright, clean school building, gesturing toward the entrance as a symbol of opportunity and growth.', 'Hope', 'Build confidence'),
        'work': ('Olitun carefully carrying out a task, like neatly filing books or designing a wooden model, demonstrating capability and responsibility.', 'Confidence', 'Complete a task'),
        'idea': ('Olitun with a bright lightbulb icon appearing above them, looking upward with a spark of creativity and innovation.', 'Curiosity', 'Create something useful'),
    }
    
    matched_override = None
    if not is_sentence:
        for kw, vals in vocab_visual_overrides.items():
            if kw in meaning_l:
                matched_override = vals
                break
                
    if matched_override:
        image_direction, emotion, character_goal = matched_override
    else:
        # Use scenic image direction generator
        image_direction = generate_scenic_image_direction(meaning, stage, speaker_desc, dialogue_rule, index)

    body_language, learning_moment = get_body_language_and_learning_moment(emotion, speaker_desc)

    return {
        'emotion': emotion,
        'storyArc': story_arc,
        'growthValue': growth_value,
        'characterGoal': character_goal,
        'imageDirection': image_direction,
        'bodyLanguage': body_language,
        'learningMoment': learning_moment,
    }


# ── OFFSET-BASED UPGRADE PROCEDURE ─────────────────────────────────────────

def upgrade_file_in_place(file_path, is_sentence=False):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Identify all Lesson IDs and their offsets in the file
    lesson_matches = list(re.finditer(r"'id':\s*'(lesson_(?:vocab|sentences)_\w+)'", content))
    
    # 2. Find all LessonBlockModel blocks in the file using newline-based boundary
    block_matches = list(re.finditer(r"LessonBlockModel\((.*?)\n\s*\),?", content, re.DOTALL))
    
    # 3. For each block, find the active lesson ID
    upgrades = []
    
    # Track index of blocks within the current active lesson
    current_lesson_id = None
    block_index_in_lesson = 0
    
    for block in block_matches:
        block_offset = block.start()
        
        # Find active lesson ID at this block's offset
        active_lesson_match = None
        for lm in lesson_matches:
            if lm.start() < block_offset:
                active_lesson_match = lm
            else:
                break
                
        if not active_lesson_match:
            continue
            
        active_id = active_lesson_match.group(1)
        if active_id != current_lesson_id:
            current_lesson_id = active_id
            block_index_in_lesson = 0
            
        block_content = block.group(1)
        
        # Parse textOlChiki and textLatin (robust to single/double quotes)
        ol_match = re.search(r"textOlChiki:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
        b_ol = ol_match.group(1) if ol_match else ''
        
        latin_match = re.search(r"textLatin:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
        b_latin = latin_match.group(1) if latin_match else ''
        
        type_match = re.search(r"type:\s*['\"](.*?)['\"],", block_content, re.DOTALL)
        b_type = type_match.group(1) if type_match else 'text'
        
        # Unescape single quotes to obtain clean Python strings
        clean_latin = b_latin.replace("\\'", "'")
        clean_ol = b_ol.replace("\\'", "'")
        
        # Extract clean English meaning
        meaning = clean_latin
        if '–' in clean_latin:
            meaning = clean_latin.split('–')[1].strip()
        elif '-' in clean_latin:
            meaning = clean_latin.split('-')[1].strip()
        elif ':' in clean_latin:
            meaning = clean_latin.split(':')[1].strip()
            
        # Generate metadata (as clean Python strings)
        meta = generate_block_data(current_lesson_id, clean_latin, clean_ol, meaning, block_index_in_lesson, is_sentence)
        
        # Escape all fields for Dart single-quoted literals
        b_ol_escaped = clean_ol.replace("'", "\\'")
        b_latin_escaped = clean_latin.replace("'", "\\'")
        
        escaped_meta = {}
        for key in ['emotion', 'storyArc', 'growthValue', 'characterGoal', 'imageDirection', 'bodyLanguage', 'learningMoment']:
            escaped_meta[key] = meta[key].replace("'", "\\'")
            
        # Create replacement string
        replacement = f"""LessonBlockModel(
            type: '{b_type}',
            textOlChiki: '{b_ol_escaped}',
            textLatin: '{b_latin_escaped}',
            data: const {{
              'emotion': '{escaped_meta['emotion']}',
              'storyArc': '{escaped_meta['storyArc']}',
              'growthValue': '{escaped_meta['growthValue']}',
              'characterGoal': '{escaped_meta['characterGoal']}',
              'imageDirection': '{escaped_meta['imageDirection']}',
              'bodyLanguage': '{escaped_meta['bodyLanguage']}',
              'learningMoment': '{escaped_meta['learningMoment']}',
            }},
          ),"""
        
        upgrades.append((block.start(), block.end(), replacement))
        block_index_in_lesson += 1

    # 4. Rebuild the file from back to front to preserve offsets
    upgraded_content = content
    for start, end, replacement in reversed(upgrades):
        upgraded_content = upgraded_content[:start] + replacement + upgraded_content[end:]
        
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(upgraded_content)
        
    print(f"Successfully upgraded {os.path.basename(file_path)} in place! Block count: {len(upgrades)}")

# Execute in-place upgrades
upgrade_file_in_place(vocab_path, is_sentence=False)
upgrade_file_in_place(sentence_path, is_sentence=True)
