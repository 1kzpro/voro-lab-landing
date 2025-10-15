import { FadeIn } from "@/components/FadeIn";
import { Footer } from "@/components/Footer";
import { InquiryForm } from "@/components/InquiryForm";

export default function InquiryPage() {
  return (
    <main className="min-h-screen">
      {/* Hero Section */}
      <section className="flex flex-col items-center justify-center min-h-screen px-6 md:px-16 lg:px-24">
        <FadeIn className="text-center" immediate>
          <h1 className="font-sora font-bold text-[clamp(36px,6vw,72px)] tracking-tight mb-3 md:mb-4">
            Get In Touch
          </h1>
          <p className="font-inter font-normal text-[clamp(16px,2.4vw,24px)] tracking-[0.02em] mb-8">
            Let's create something real together.
          </p>
        </FadeIn>
      </section>

      {/* Form Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24">
        <FadeIn delay={0.1}>
          <InquiryForm />
        </FadeIn>
      </section>

      {/* Footer */}
      <Footer navDelay={0.2} copyrightDelay={0.3} />
    </main>
  );
}
