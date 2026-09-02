import type { Plugin } from "@opencode-ai/plugin"
import { appendFile, mkdir } from "node:fs/promises"
import { join } from "node:path"

// Logs every opencode bus event to .opencode/logs/events.jsonl (one JSON per line).
// Set the LOG_ALL_EVENTS output flag (true) to also print events to stderr/stdout.

export const EventLoggerPlugin: Plugin = async ({ directory }) => {
  const logFile = join(directory, ".opencode", "logs", "events.jsonl")
  await mkdir(join(directory, ".opencode", "logs"), { recursive: true })

  return {
    event: async ({ event }) => {
      const line = JSON.stringify({ ts: Date.now(), ...event })
      try {
        await appendFile(logFile, line + "\n", "utf8")
      } catch (err) {
        console.error(`[event-logger] failed to write: ${(err as Error).message}`)
      }
    },
  }
}

export default EventLoggerPlugin
