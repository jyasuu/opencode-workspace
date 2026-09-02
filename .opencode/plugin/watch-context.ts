import type { Plugin } from "@opencode-ai/plugin"
import { readFile } from "node:fs/promises"
import { join } from "node:path"

const DEFAULT_WATCH_FILE = "watched.txt"

export const WatchContextPlugin: Plugin = async ({ directory }, options = {}) => {
  const watchFile = (options as { file?: string }).file ?? DEFAULT_WATCH_FILE
  const watchPath = join(directory, watchFile)

  return {
    "experimental.chat.system.transform": async (_input, output) => {
      try {
        const content = await readFile(watchPath, "utf8")
        const injected = `\n[Context from ${watchFile}]\n${content}`
        if (output.system.includes(injected)) return
        output.system.push(injected)
      } catch {
        // file missing/unreadable — skip silently
      }
    },
  }
}

export default WatchContextPlugin
