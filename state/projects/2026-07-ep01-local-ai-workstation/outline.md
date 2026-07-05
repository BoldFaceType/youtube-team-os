# Outline: $200 Lenovo P520 + RTX 3090 Local AI Workstation

Project: 2026-07-ep01-local-ai-workstation

## Hook (0:00–0:30)
The ugly $200 tower reveal + the claim: this thing runs a 70B model, for less than a year of ChatGPT Plus. Hard-cut to the tokens/sec counter. Question that keeps them: can a machine an office threw out really replace the cloud?

## Intro / Promise (0:30–1:00)
Promise: full build, honest LM Studio benchmarks across 7B/13B/34B/70B, and a total cost at the end so you know exactly what it takes to copy this. State the one thing that makes it possible: 24GB of VRAM on a used 3090.

## Section 1: Why the Lenovo P520 (1:00–3:00)
- The base machine is a used enterprise workstation — quiet, built to run 24/7, and critically it has the power delivery a 3090 needs with no adapters.
- What to buy: P520 (not the smaller variants), aim for the 690W+ PSU config, Xeon W-21xx, 32GB+ ECC.
- What to avoid: underpowered PSU SKUs, missing GPU power cables.
- Transition: you've got the base — now the part that actually does the AI work.

## Section 2: The Used RTX 3090 Value Case (3:00–5:00)
- Why 3090 over 4070/4080: 24GB VRAM is the number that decides which models fit. VRAM > raw speed for local LLMs.
- Buying used safely: check memory-junction temps, avoid thrashed mining cards, test all fans, reseat thermal pads if temps are high.
- Price reality: used 3090 ~$600–750; a new 24GB card is 2–3x that.
- Transition: parts in hand — let's put it together, including the one cable gotcha.

## Section 3: The Build (5:00–7:00)
- Physical install: tool-less bays, the 3090 clears the case, seat it fully.
- The PSU cable gotcha: use the workstation's native connectors, never a daisy-chained single cable for a 350W card.
- BIOS: enable Resizable BAR / Above 4G Decoding; update to latest BIOS.
- Drivers: clean NVIDIA studio driver install, verify with nvidia-smi.
- Transition: it powers on and sees the GPU — now the moment of truth, the benchmarks.

## Section 4: LM Studio Benchmarks — The Payoff (7:00–10:30)
- Set up LM Studio, explain GPU offload layers and quantization in one breath.
- Walk the numbers table on screen: 7B, 13B, 34B, 70B (Q4). Tokens/sec, whether it fully fits in VRAM.
- The headline: 70B quantized runs, usable for chat; 34B is the sweet spot for speed+quality.
- Which quant to pick for 24GB (Q4_K_M as the default recommendation).
- Transition: it works — but should you actually build one?

## Section 5: Verdict + Total Cost (10:30–12:00)
- Full bill of materials on screen with a running total (~$850–950).
- Cost vs. a new equivalent build (~$2,500+) and vs. cloud subscriptions over 2 years.
- Who should NOT do this: people who only need a chatbot occasionally, or who can't tolerate used-hardware risk.
- Honest caveats: power draw, noise under load, no warranty.

## CTA + Close (12:00–12:30)
Ask: which model would YOU run first on this — name it in the comments. Pinned parts list + LM Studio config linked below. Tease the follow-up: fine-tuning on this exact machine. Subscribe.

## B-Roll / Visual Notes
- 0:00 Hook: slow pan over the beige tower, then eBay price screenshot, then tokens/sec counter macro.
- 1:00 P520: close-ups of PSU label, power connectors, tool-less latches.
- 3:00 3090: card beauty shots, HWiNFO memory-junction temp overlay, fan spin test.
- 5:00 Build: hands-on install, cable routing macro, BIOS screen capture, nvidia-smi terminal.
- 7:00 Benchmarks: screen recording of LM Studio, on-screen animated tokens/sec bar chart building up per model.
- 10:30 Cost: animated BOM list totaling up; side-by-side cost comparison bars.
