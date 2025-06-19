import { GlassmorphicChatbar } from "@/components/glassmorphic-chatbar"

export default function Home() {
  // The blur state is now managed globally by BlurProvider
  return (
    <main
      className="flex min-h-screen flex-col items-center justify-center p-4 bg-cover bg-center"
      style={{
        backgroundImage:
          "url('https://hebbkx1anhila5yf.public.blob.vercel-storage.com/image-C3FgrzHdNMQh9mTRQ17pCq4eCvXCfG.png')",
      }}
    >
      <GlassmorphicChatbar
        isOpen={true}
        placeholder="What can I help you with?"
        initialValue=""
        // Blur props are no longer needed here
      />
    </main>
  )
}
