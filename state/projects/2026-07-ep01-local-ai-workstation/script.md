# Script: $200 Lenovo P520 + RTX 3090 Local AI Workstation

Project: 2026-07-ep01-local-ai-workstation
Draft: 1
Word count: ~1620 (~12.5 min at 130wpm)

---

[HOOK]
This cost me two hundred dollars. {$200 — eBay} A used corporate tower somebody's IT department threw in a closet. By the end of this video, it's running a seventy-billion-parameter AI model, in my basement, offline. And the whole thing costs less than one year of a ChatGPT Plus subscription. [B-roll: slow pan across the beige-black tower, then hard-cut to LM Studio tokens-per-second counter flying] So here's the real question: can a machine an office literally threw away actually replace the cloud? Let's find out.

[INTRO]
Here's exactly what you're getting in the next ten minutes. The full build, start to finish. Real LM Studio benchmarks — not marketing numbers, actual tokens per second across four model sizes. And at the end, the total cost, so you know exactly what it takes to copy this. There's one thing that makes all of it possible, and it's not the processor. It's twenty-four gigabytes of video memory on a used RTX 3090. Keep that number in your head. {24GB VRAM} Everything comes back to it.

[SECTION 1: Why the Lenovo P520]
Let's start with the base machine, because this is where most people overspend. This is a Lenovo ThinkStation P520. It's a used enterprise workstation, which means two things that matter to us. It was built to run twenty-four seven without dying, and it has the power delivery a big GPU needs — with no sketchy adapters. [B-roll: close-up of the PSU wattage label and the spare GPU power connectors] That second part is the secret. Most cheap prebuilt desktops physically can't power a card like a 3090. This one can, straight out of the box.

If you go shopping for one, here's what to look for. Get the full-size P520, not the smaller variants. Aim for the six-hundred-and-ninety-watt power supply configuration or higher. {Look for: 690W PSU} A Xeon W-2100 series chip is plenty, and thirty-two gigs of ECC memory is common and cheap. And here's what to avoid: listings with an underpowered supply, or ones missing the GPU power cables. Ask the seller for a photo of the connectors before you buy.

So you've got the base. But the base doesn't do any AI work on its own. The part that does — that's next, and it's the single most important buy in this whole build.

[SECTION 2: The Used RTX 3090 Value Case]
This is a used RTX 3090. [B-roll: card beauty shots, rotating] Now, you might be asking — why a two-generation-old card? Why not a newer 4070 or 4080? One reason. Video memory. Remember that number, twenty-four gigabytes. For gaming, newer cards win. But for running AI models locally, the amount of VRAM decides which models even fit on the card at all. And a used 3090 gives you twenty-four gigs for way less money than any current card with the same memory. {VRAM beats raw speed for local AI}

Buying used does mean you have to be a little careful. Three quick checks. One: look at the memory-junction temperature under load — if it's spiking past a hundred and ten degrees, the thermal pads are shot. [B-roll: HWiNFO overlay showing memory-junction temp] Two: be cautious with obvious ex-mining cards that ran hot for years. Three: test every fan. If temps are ugly, a twenty-dollar thermal pad replacement usually fixes it. A used 3090 runs about six to seven-fifty right now. A brand-new card with the same twenty-four gigs? Two to three times that.

Alright — parts in hand. Let's actually put this thing together. And there's exactly one cable mistake that fries people's builds, so stick around for that.

[SECTION 3: The Build]
The physical install is genuinely easy, and that's another reason I love this case. The bays are tool-less, the 3090 clears everything, and it seats right into the top slot. [B-roll: hands seating the GPU, latch clicking] Push until it clicks and the latch closes.

Now, the gotcha I promised. Power. The 3090 pulls around three hundred and fifty watts. Use the workstation's native power cables from the supply — the dedicated GPU connectors. {Never daisy-chain one cable} Do not run one single cable daisy-chained into both power ports on a card that hungry. That's how you get instability, or worse. Use two separate leads.

Two more things and we're live. In the BIOS, enable Resizable BAR and Above 4G Decoding, and update to the latest BIOS while you're in there. [B-roll: BIOS screen, cursor toggling Above 4G Decoding] Then boot into Windows, do a clean NVIDIA studio driver install, and confirm the card is seen. Open a terminal, type nvidia-smi, and you should see the 3090 and all twenty-four gigs staring back at you. [B-roll: terminal showing nvidia-smi output]

It powers on. It sees the GPU. So now — the moment this whole video has been building toward. Does it actually run the models?

[SECTION 4: LM Studio Benchmarks — The Payoff]
We're using LM Studio, because it's the easiest way to run these models with a real interface. [B-roll: LM Studio window opening] Two settings matter. GPU offload — that's how many layers of the model live on the graphics card instead of system memory. More on the card means faster. And quantization — think of it as compressing the model so it fits in less memory, trading a tiny bit of quality for a lot of speed. For twenty-four gigs, Q4 is your friend. {Quantization = fits more model in VRAM}

Now the numbers. Watch the chart. [B-roll: animated tokens-per-second bar chart building per model] A seven-billion-parameter model runs completely on the card and absolutely flies — well over a hundred tokens per second. Faster than you can read. A thirteen-billion model, still fully on the GPU, still very fast. A thirty-four-billion model — this is the sweet spot — great answers, comfortably usable speed, fully in VRAM. {34B = the sweet spot} And the big one. A seventy-billion model, quantized to Q4. It runs. It's usable for chat. Not instant, but genuinely good — on a two-hundred-dollar base machine. Let that sink in.

If you take one recommendation from this whole video, it's this: for a twenty-four gig card, grab the Q4_K_M quant of whatever model you want. {Recommended: Q4_K_M} Best balance of speed and quality for this exact hardware.

It works. The dream works. But — and I promised you honesty — should you actually build one? Let's talk money and the catch.

[SECTION 5: Verdict + Total Cost]
Here's the full bill of materials. [B-roll: animated BOM list totaling up on screen] Two hundred for the P520 base. Call it six-fifty for a good used 3090. A little for extra memory and a fresh set of thermal pads. Your total lands somewhere around eight-fifty to nine-fifty, all in. {Total: ~$900}

Compare that to a new build with the same capability — you're looking at twenty-five hundred dollars, easily. And compare it to the cloud: two years of stacked AI subscriptions runs well past what this whole machine cost, and at the end you own nothing. Here, you own it, it's private, and it's offline.

Now the honest part, because this isn't for everyone. If you only need a chatbot once in a while, just pay for the cloud — this is overkill. If you can't tolerate the risk of buying used hardware with no warranty, this isn't your move. And yes — under full load it draws real power and the fans get audible. [B-roll: power meter showing wattage under load] Those are the trade-offs. For me, for what I do, they're absolutely worth it.

[CTA]
So I want to know: which model would you run first on a machine like this? Name it in the comments — I'm genuinely curious what you'd pick. The full parts list and my exact LM Studio config are pinned and linked in the description, so you can copy this build one-to-one. And next video, I'm taking this same two-hundred-dollar tower and fine-tuning a model on it — so if that sounds fun, subscribe and I'll see you there. Thanks for watching.
