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

# ── Stack chapter (Chapter 2 — Castle of Echoes) ─────────────────────────────

static func stack_level_intro(level: int) -> Array:
	match level:
		1:
			return [
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"Welcome to the Castle of Echoes. Magic here works in a peculiar way — spells must be UNDONE in the exact reverse order they were cast."},
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"This is a STACK. Last In, First Out. I cast spells onto it. You must POP them in reverse — or the castle collapses!"},
				{"speaker":"You","portrait":"player",
				 "text":"So if Fire is cast first and Ice second... I pop Ice first, then Fire?"},
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"Exactly! LIFO. Click the TOP rune to pop it. Never try to grab from the middle."},
			]
		2:
			return [
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"More spells, more depth. The stack grows taller. Remember — you can ONLY access the top."},
				{"speaker":"You","portrait":"player",
				 "text":"So the rune I pushed first is completely buried? I can't reach it until everything above is gone?"},
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"Precisely. That's the fundamental constraint of a stack. Access is strictly LIFO."},
			]
		3:
			return [
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"Notice something? If I push A, B, C... and you pop them... you get C, B, A. The sequence is REVERSED."},
				{"speaker":"You","portrait":"player",
				 "text":"A stack automatically reverses whatever you put in it. That's actually useful!"},
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"Compilers use this for function calls. Undo systems use it. Even your browser back button is a stack!"},
			]
		4:
			return [
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"Before you pop, PREDICT what's in the stack. Press Q to open the stack panel — study it."},
				{"speaker":"You","portrait":"player",
				 "text":"So I need to visualize the internal state before acting. Think before you pop."},
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"In real programming, a debugger shows you the call stack. Today, I'm your debugger."},
			]
		5:
			return [
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"The full tower — 6 runes maximum. Push one too many and the whole thing OVERFLOWS. The castle crumbles."},
				{"speaker":"You","portrait":"player",
				 "text":"Stack overflow... that's why programs crash when functions call themselves infinitely?"},
				{"speaker":"Court Wizard","portrait":"doorman",
				 "text":"Now you understand. Every recursion, every function call — it all goes on the call stack. Fill it up and crash."},
			]
		_: return []

# ── Linked List chapter (Chapter 3 — Chain Train) ────────────────────────────

static func ll_level_intro(level: int) -> Array:
	match level:
		1:
			return [
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"This is the Chain Train. Each carriage knows only one thing: which carriage comes NEXT."},
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"That's a Linked List. No indexes. No random access. You traverse by following the NEXT pointer, one by one."},
				{"speaker":"You","portrait":"player",
				 "text":"So to find carriage 5, I have to go through carriages 1, 2, 3, 4 first? That seems slow."},
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"O(n) traversal, yes. But insertion and deletion? O(1) — no shifting needed. Every structure has its trade-off."},
			]
		2:
			return [
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Inserting a new carriage: find the insertion point, update the previous carriage's NEXT pointer to the new one."},
				{"speaker":"You","portrait":"player",
				 "text":"And the new carriage's NEXT points to what came after the insertion point?"},
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Exactly. Two pointer updates. Compare that to an array insert — every element after shifts. Linked lists win here."},
			]
		3:
			return [
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Deletion: skip the carriage you want gone. Point the previous carriage's NEXT directly to the one after it."},
				{"speaker":"You","portrait":"player",
				 "text":"The deleted carriage still exists in memory for a moment — it's just unreachable?"},
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Yes. In garbage-collected languages it gets cleaned up. In C, you must free() it yourself or it leaks."},
			]
		4:
			return [
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Reversal: flip every NEXT pointer. Head becomes tail, tail becomes head. One pass — O(n)."},
				{"speaker":"You","portrait":"player",
				 "text":"Do I need extra memory to do this?"},
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Just three pointers: previous, current, next. That's it. O(1) space. Elegance in simplicity."},
			]
		5:
			return [
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Mixed operations. Traverse, insert, delete, reverse — all in one journey. This is real-world linked list usage."},
				{"speaker":"You","portrait":"player",
				 "text":"When would I actually use a linked list over an array?"},
				{"speaker":"Train Conductor","portrait":"doorman",
				 "text":"Frequent insertions/deletions at arbitrary positions. Music playlists. Browser history. Undo chains. Now go!"},
			]
		_: return []

# ── Tree chapter (Chapter 4 — Oracle's Forest) ───────────────────────────────

static func tree_level_intro(level: int) -> Array:
	match level:
		1:
			return [
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"The Oracle's Forest is a Binary Search Tree. Every node has at most two children — left and right."},
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"The rule: left child is always SMALLER. Right child is always LARGER. This lets us search in O(log n)."},
				{"speaker":"You","portrait":"player",
				 "text":"So searching for 42: if root is 50, I go left. If that's 30, I go right. Each step halves the possibilities?"},
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"Precisely. Binary search in tree form. Click the correct child at each step."},
			]
		2:
			return [
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"Insertion: search for where the value WOULD be, then place it there as a leaf."},
				{"speaker":"You","portrait":"player",
				 "text":"So it always ends up at the bottom? Inserted values are always leaves first?"},
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"In a standard BST, yes. The shape of the tree depends entirely on insertion order — a weakness we'll address later."},
			]
		3:
			return [
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"Deletion has three cases. Leaf: just remove. One child: replace with that child. Two children: replace with inorder successor."},
				{"speaker":"You","portrait":"player",
				 "text":"What's an inorder successor?"},
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"The smallest value in the right subtree. It maintains BST order when it takes the deleted node's place."},
			]
		4:
			return [
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"An AVL Tree self-balances. After every insert/delete, it checks the balance factor of each node."},
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"If |left_height - right_height| > 1 at any node, it ROTATES to restore balance. O(log n) guaranteed."},
				{"speaker":"You","portrait":"player",
				 "text":"So AVL prevents the worst case where a BST becomes a straight line — O(n) search?"},
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"Exactly. Rotation is the medicine. Learn to recognize when and which direction."},
			]
		5:
			return [
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"A Max-Heap: parent is always GREATER than both children. The root is always the maximum element."},
				{"speaker":"You","portrait":"player",
				 "text":"And extracting the max takes O(log n) because we bubble down to restore the heap property?"},
				{"speaker":"Forest Oracle","portrait":"elderly",
				 "text":"Yes — heapify. This is the engine of heap sort and priority queues. Now prove your mastery."},
			]
		_: return []

# ── Graph chapter (Chapter 5 — Kingdom Roads) ────────────────────────────────

static func graph_level_intro(level: int) -> Array:
	match level:
		1:
			return [
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"The Kingdom Roads — a GRAPH. Cities are nodes. Roads are edges. Some roads have distances — weights."},
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Breadth-First Search explores level by level using a QUEUE. Start at one city, visit all neighbors before going deeper."},
				{"speaker":"You","portrait":"player",
				 "text":"So BFS finds the shortest path in terms of number of edges — not weighted distance?"},
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Correct. Click cities in BFS order — the queue shows you what to visit next."},
			]
		2:
			return [
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Depth-First Search uses a STACK — go as deep as possible before backtracking."},
				{"speaker":"You","portrait":"player",
				 "text":"So DFS might visit a city far away before visiting a neighbor that's right next door?"},
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Exactly. DFS is used for cycle detection, topological sort, and maze solving. Different tool for different jobs."},
			]
		3:
			return [
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Dijkstra's Algorithm: always expand the CLOSEST unvisited city. Use a priority queue."},
				{"speaker":"You","portrait":"player",
				 "text":"So I greedily pick the minimum-distance city each step? And that guarantees the shortest path?"},
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Yes — with non-negative edge weights. Never pick a city just because it's a neighbor. Pick the cheapest."},
			]
		4:
			return [
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Cycle detection with DFS: if you find an edge to an already-visited node in the current path — that's a cycle."},
				{"speaker":"You","portrait":"player",
				 "text":"The 'back edge' — it goes back to an ancestor in the DFS tree?"},
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Exactly. Track which nodes are in the current recursion stack. A back edge = cycle confirmed."},
			]
		5:
			return [
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Topological Sort: order cities so every directed road points forward — no going back."},
				{"speaker":"You","portrait":"player",
				 "text":"This only works on Directed Acyclic Graphs — DAGs?"},
				{"speaker":"Kingdom Cartographer","portrait":"merchant",
				 "text":"Correct. Use Kahn's algorithm: find nodes with in-degree 0, process them, reduce neighbors' in-degree. Repeat."},
			]
		_: return []
