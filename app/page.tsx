import { FadeIn } from "@/components/FadeIn";

export default function Home() {
  return (
    <main className="min-h-screen">
      {/* Hero Section */}
      <section className="flex flex-col items-center justify-center min-h-screen px-6 md:px-16 lg:px-24">
        <FadeIn className="text-center">
          <h1 className="font-sora font-bold text-[clamp(36px,6vw,72px)] tracking-tight mb-3 md:mb-4">
            VORO LAB
          </h1>
          <p className="font-inter font-normal text-[clamp(16px,2.4vw,24px)] tracking-[0.02em]">
            Real content. Real presence.
          </p>
        </FadeIn>
      </section>

      {/* Intro Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24">
        <FadeIn delay={0.1}>
          <p className="text-[17px] md:text-[18px] leading-relaxed mb-6">
            Hi, I&apos;m Kazybek — the person behind Voro Lab.
          </p>
          <p className="text-[17px] md:text-[18px] leading-relaxed">
            I create real, authentic social‑media content for Bay Area brands
            and businesses. On-site footage, no fake energy — just your story,
            your people, and your presence brought to life through short,
            engaging videos and visuals.
          </p>
        </FadeIn>
      </section>

      {/* Services Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24">
        <FadeIn delay={0.2}>
          <ul className="space-y-4 text-[17px] md:text-[18px]">
            <FadeIn delay={0.25}>
              <li className="leading-relaxed">
                → Social media content production
              </li>
            </FadeIn>
            <FadeIn delay={0.3}>
              <li className="leading-relaxed">
                → Short‑form videos & photography
              </li>
            </FadeIn>
            <FadeIn delay={0.35}>
              <li className="leading-relaxed">
                → Monthly content days for local Bay Area businesses
              </li>
            </FadeIn>
          </ul>
        </FadeIn>
      </section>

      {/* CTA Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24 text-center">
        <FadeIn delay={0.4}>
          <p className="text-[17px] md:text-[18px] leading-relaxed mb-6">
            Let&apos;s create something real together.
          </p>
          <a
            href="https://instagram.com/voro.lab"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block text-[20px] md:text-[22px] font-bold text-soft-white hover:text-pure-white transition-colors duration-200"
          >
            @voro.lab
          </a>
        </FadeIn>
      </section>

      {/* Footer */}
      <footer className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-8 md:py-12">
        <FadeIn delay={0.5}>
          <small className="block text-center text-sm opacity-50">
            © 2025 Voro Lab — Bay Area. Real content. Real presence.
          </small>
        </FadeIn>
      </footer>
    </main>
  );
}
