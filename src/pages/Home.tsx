import { GlassmorphicChatbar } from "@/components/glassmorphic-chatbar"

export default function Home() {
  return (
    <main className="flex h-full w-full items-center justify-center p-4">
      <GlassmorphicChatbar
        isOpen={true}
        placeholder="What can I help you with?"
        initialValue=""
      />
    </main>
  )
}
