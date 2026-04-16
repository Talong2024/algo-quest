extends Node
## DialogueScripts — all dialogue content for the game.
## Each function returns an Array of dialogue lines for DialogueBox.

# ── Opening story ─────────────────────────────────────────────────────────────

static func intro_arrival() -> Array:
	return [
		{
			"speaker": "",
			"portrait": "narrator",
			"text": "The Kingdom of AlgoQuest.\n\nA realm where order is everything — and chaos is the enemy.",
		},
		{
			"speaker": "",
			"portrait": "narrator",
			"text": "Every day, hundreds of citizens arrive at the Kingdom Gate.\nEvery day, it descends into madness.",
		},
		{
			"speaker": "Old Gatekeeper",
			"portrait": "doorman",
			"text": "Ugh... my knees! Twenty years at this gate and I can't take it anymore. Someone needs to bring ORDER to this place!",
		},
		{
			"speaker": "Old Gatekeeper",
			"portrait": "doorman",
			"text": "Hey — YOU! Yes, you! You look like you've studied Data Structures. I can tell by the look in your eyes.",
		},
		{
			"speaker": "You",
			"portrait": "player",
			"text": "Me? I just arrived here... I was looking for the university.",
		},
		{
			"speaker": "Old Gatekeeper",
			"portrait": "doorman",
			"text": "Perfect! The gate IS your university now. You're the new Doorman. Congratulations, you start immediately.",
		},
		{
			"speaker": "You",
			"portrait": "player",
			"text": "Wait, what?! I haven't agreed to anything—",
		},
		{
			"speaker": "Old Gatekeeper",
			"portrait": "doorman",
			"text": "The first rule: QUEUE. A line. First come, first served. The citizen at the FRONT gets served first. Always.",
		},
		{
			"speaker": "Old Gatekeeper",
			"portrait": "doorman",
			"text": "Get it wrong and citizens riot. Get it right and the Kingdom flows. Simple. Good luck!",
		},
		{
			"speaker": "You",
			"portrait": "player",
			"text": "...he's already gone. Alright then.\n\nFirst In, First Out. I can do this.",
		},
	]

# ── Level intros (before each level starts) ───────────────────────────────────

static func level_intro(level: int) -> Array:
	match level:
		1:
			return [
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Alright rookie. See those citizens? They arrived in a specific order. You serve them in that SAME order. Whoever came first — leaves first.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "This is called a Queue. Think of it like a line at a shop. You don't jump to the front just because you feel like it.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "So I press SPACE to serve the front person. Simple enough.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Serve the WRONG person and you'll lose a life. They don't like being skipped. Trust me on that one.",
				},
			]
		2:
			return [
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Good work on level one! But now the REAL challenge begins. The gate can only hold so many people.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "What happens when the queue is full?",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "OVERFLOW. New citizens can't join — they're turned away. We call it a Bounded Queue. Capacity has a limit.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Every real computer queue has this problem — a network buffer, a print queue, a message queue. Fill it up and data is lost.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "So I need to serve fast enough that there's always room. Got it.",
				},
			]
		3:
			return [
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Listen carefully. Monsters have started sneaking into the queue disguised as citizens. Do NOT let them through the gate!",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "If you see a SKELETON or ORC in the queue — serve them and you lose a life. You must REJECT them or let their patience expire.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "So I'm managing patience timers AND watching for monsters? That's... intense.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Welcome to real systems work. TTL, expiry policies, AND security filters — all at once.",
				},
				{
					"speaker": "Elderly Citizen",
					"portrait": "elderly",
					"text": "Excuse me, young Doorman... I've been waiting a long time. My patience... it won't hold forever.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "Oh! I'm sorry — I'll get to you as soon as—",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Pay attention! Elderly citizens have a TIME LIMIT. That purple bar above their head — when it empties, they leave. And you lose a life.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "In computer science this is called a TTL — Time To Live. Queue items don't wait forever. Sometimes you must break strict FIFO order to prevent losing them.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "So I might have to serve an elderly citizen early, even if they're not at the front?",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Now you're thinking like a real system architect. Rules exist — but so do exceptions.",
				},
			]
		4:
			return [
				{
					"speaker": "",
					"portrait": "narrator",
					"text": "A royal herald arrives at the gate with an urgent message...",
				},
				{
					"speaker": "Royal Herald",
					"portrait": "king",
					"text": "BY DECREE OF THE KING! VIP guests must be processed before common citizens. Adjust the queue IMMEDIATELY.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "But... that's not how a regular queue works. That breaks FIFO completely.",
				},
				{
					"speaker": "Royal Herald",
					"portrait": "king",
					"text": "This is a PRIORITY QUEUE now. Lower priority number means higher rank. VIPs are priority 1. Normal citizens are priority 3.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Priority Queues are everywhere — hospital triage, CPU task scheduling, Dijkstra's algorithm. Important things jump ahead.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "So when a VIP arrives, I drag them to the correct position based on their priority number. Then serve from the front.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Exactly. Get the order wrong and the gate jams. The citizens will NOT be pleased.",
				},
			]
		5:
			return [
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Congratulations — you've made it to the final challenge. The King has opened a SECOND gate. One at the front, one at the back.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "Two gates? Can't people just... pick whichever one they want?",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "No! This is a Deque — a Double-Ended Queue. Items can enter and exit from EITHER end. But each citizen has a specific gate they must use.",
				},
				{
					"speaker": "Merchant",
					"portrait": "merchant",
					"text": "We merchants must exit through the back gate! Our carts won't fit through the front entrance.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "So I press F for the front gate and B for the back gate. And I need to check which gate each citizen requires.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Route the wrong citizen through the wrong gate and chaos erupts. You've come so far — don't fail now.",
				},
			]
		_:
			return []

# ── Post-level reactions ──────────────────────────────────────────────────────

static func level_complete_reaction(level: int, score: int) -> Array:
	match level:
		1:
			return [
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Well done! The queue held and nobody rioted. You understand FIFO now — it's the heartbeat of orderly systems.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "It's actually satisfying. When the order is right, everything just... flows.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "That's exactly it. On to the next challenge — this one gets trickier.",
				},
			]
		2:
			return [
				{
					"speaker": "You",
					"portrait": "player",
					"text": "That was intense! I barely kept the queue from overflowing at the end.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Good! Now you understand why engineers obsess over queue capacity. Overflow crashes systems — real ones, not just gates.",
				},
			]
		3:
			return [
				{
					"speaker": "Elderly Citizen",
					"portrait": "elderly",
					"text": "Thank you, dear Doorman! You saw me struggling and helped me in time. Your kind heart serves this kingdom well.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "I'm learning that rules are important — but knowing WHEN to bend them is just as important.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Now you sound like a senior engineer. TTL, expiry policies, graceful degradation — you're thinking in systems.",
				},
			]
		4:
			return [
				{
					"speaker": "Royal Herald",
					"portrait": "king",
					"text": "The King is pleased! Order was maintained even with Royal Priority overrides. You understand Priority Queues.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "It's like a heap data structure, isn't it? The highest priority always bubbles to the top.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "Exactly! Heaps, priority queues — same idea. One more gate to go. The final test awaits.",
				},
			]
		5:
			return [
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "I... I can't believe it. You mastered all five queue concepts. Queue, Overflow, TTL, Priority, Deque.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "It wasn't just about managing a gate. I actually understand how computer systems handle ordering now.",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "The Kingdom thanks you. And so do I. Now go — the Stack chapter awaits. They say the Castle of Echoes is... different.",
				},
				{
					"speaker": "You",
					"portrait": "player",
					"text": "Different how?",
				},
				{
					"speaker": "Old Gatekeeper",
					"portrait": "doorman",
					"text": "In the Stack, the LAST one in is the FIRST one out. Everything is reversed. Good luck.",
				},
			]
		_:
			return []

# ── Wrong answer reactions (contextual) ──────────────────────────────────────

static func wrong_fifo_reaction(skipped_name: String) -> Array:
	return [
		{
			"speaker": skipped_name,
			"portrait": "elderly",
			"text": "EXCUSE ME! I was here FIRST! This is outrageous! Do you not know what a queue is?!",
		},
	]

static func overflow_reaction() -> Array:
	return [
		{
			"speaker": "Citizen",
			"portrait": "elderly",
			"text": "There's no room! The queue is FULL! I'm being turned away! This is unacceptable!",
		},
		{
			"speaker": "Old Gatekeeper",
			"portrait": "doorman",
			"text": "SERVE FASTER! When the queue is full, new arrivals can't join. That's an overflow error!",
		},
	]
