import { FadeIn } from "@/components/FadeIn";
import { Footer } from "@/components/Footer";

export default function Home() {
  return (
    <main className="min-h-screen">
      {/* Hero Section */}
      <section className="flex flex-col items-center justify-center min-h-screen px-6 md:px-16 lg:px-24">
        <FadeIn className="text-center" immediate>
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
          <p className="text-[17px] md:text-[18px] leading-relaxed mb-8">
            Let&apos;s create something real together.
          </p>
          <div className="space-y-6">
            <div>
              <a
                href="/offer"
                className="inline-block bg-soft-white text-soft-black px-8 py-4 rounded-lg text-[18px] md:text-[20px] font-bold hover:bg-pure-white transition-colors duration-200"
              >
                Get No-Cost Social Media Content
              </a>
            </div>
            <div>
              <a
                href="/inquiry"
                className="inline-block border-2 border-soft-white text-soft-white px-8 py-4 rounded-lg text-[18px] md:text-[20px] font-bold hover:bg-soft-white hover:text-soft-black transition-colors duration-200"
              >
                Send Inquiry
              </a>
            </div>
            <div className="text-sm opacity-70">or connect with me</div>
            <a
              href="https://instagram.com/voro.lab"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-block text-[20px] md:text-[22px] font-bold text-soft-white hover:text-pure-white transition-colors duration-200"
            >
              @voro.lab
            </a>
          </div>
        </FadeIn>
      </section>

      {/* Footer */}
      <Footer navDelay={0.5} copyrightDelay={0.6} />
    </main>
  );
}
