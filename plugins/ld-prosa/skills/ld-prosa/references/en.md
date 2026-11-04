# English prose

Read this before writing English: chat when the locale is `en`, and always for
artifacts — commit messages, PR bodies, tickets, docs — when
`LD_PROSA_ARTIFACTS=en`.

One question decides: **who does what?** If the reader has to rebuild the agent
or the action, the sentence was compressed past the point where it communicates.
The six items below are symptoms of that, not a list to memorise; a bad case
usually shows three at once.

## Six ways English hides the agent

The paper (arXiv 2610.29162) measures most of these as processing costs that
frontier models overuse. Each pair keeps the meaning and restores the agent.

1. **Inanimate subject with an animate verb.** "The config decides which plugin
   loads" → "The loader reads the config to choose the plugin." Personification
   is fine when the actor is obvious; the tell is a verb that needs a human.
2. **Three nouns stacked.** "user token refresh failure handler" → "the handler
   that runs when a user's token fails to refresh". The reader has to guess the
   bracketing.
3. **A reduced relative.** "the value passed to the loader" → "the value that
   the loader receives". The agent is still there, buried under the participle.
4. **An object relative where an active clause fits.** "the table that the
   migration creates" → "the migration creates the table". The relative buys a
   longer dependency for nothing.
5. **A long dependency chain.** "The service that the hook, which the plugin
   registers at startup, calls on every request" → split it in two. Working
   memory pays for every word between the subject and its verb.
6. **A denominal verb or a novel compound.** "calendar it", "footnote the
   decision", "latency-budgeted retry envelope" → "put it on the calendar", "note
   it in a footnote", "a retry policy with a latency budget". A noun turned into
   a verb forces a re-parse of the part of speech.

## False positives

A clean human writer hits these with no AI involved. Never rewrite for one
marker; act on a cluster.

- Perfect grammar and a consistent style. Edited writers exist.
- A dry, unsentimental voice, or mixed casual and formal registers.
- Formal vocabulary. The tell is a specific set of overused words, not every
  polysyllable.
- One em dash, one short emphatic sentence, one "honestly", one "however".
- Curly quotes or tidy formatting; editors and CMSes produce both.
- Unsourced claims. Most of the web has no citations.
- A letter-style greeting or sign-off.

## Preserve

These are evidence of a person writing; editing them out makes the text worse.

- Specific, hard-to-fabricate detail: a real path, an error string, a date.
- Unresolved tension or a position the writer can defend.
- Varied sentence length. A short sentence after two long ones is human.
- Self-corrections and genuine parentheticals.
- Dated references, slang, in-jokes.

Sources: Clark, Martin & Mahowald, _Why is AI-generated language so hard to
understand?_ (2026); Wikipedia's _Signs of AI writing_, as collected by the
`humanizer` skill.
