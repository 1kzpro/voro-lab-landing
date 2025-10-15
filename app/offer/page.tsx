import { FadeIn } from "@/components/FadeIn";
import { Footer } from "@/components/Footer";
import Link from "next/link";

export default function Offer() {
  return (
    <main className="min-h-screen">
      {/* Hero Section */}
      <section className="flex flex-col items-center justify-center min-h-screen px-6 md:px-16 lg:px-24">
        <FadeIn className="text-center" immediate>
          <h1 className="font-sora font-bold text-[clamp(36px,6vw,72px)] tracking-tight mb-3 md:mb-4">
            NO-COST SOCIAL MEDIA
          </h1>
          <p className="font-inter font-normal text-[clamp(16px,2.4vw,24px)] tracking-[0.02em]">
            For Bay Area Businesses
          </p>
        </FadeIn>
      </section>

      {/* Intro Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24">
        <FadeIn delay={0.1}>
          <p className="text-[17px] md:text-[18px] leading-relaxed">
            I&apos;m expanding my creative portfolio and offering no-cost,
            no-obligation social media management for a few local businesses.
          </p>
        </FadeIn>
      </section>

      {/* What You Get Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24">
        <FadeIn delay={0.2}>
          <h2 className="font-sora font-bold text-[clamp(24px,4vw,36px)] tracking-tight mb-8">
            You&apos;ll get:
          </h2>
          <ul className="space-y-6 text-[17px] md:text-[18px]">
            <FadeIn delay={0.25}>
              <li className="leading-relaxed flex items-start">
                <span className="text-soft-white mr-3">→</span>
                <div>
                  <strong>On-site content creation</strong> — I&apos;ll capture
                  your real environment, team, and work in action.
                </div>
              </li>
            </FadeIn>
            <FadeIn delay={0.3}>
              <li className="leading-relaxed flex items-start">
                <span className="text-soft-white mr-3">→</span>
                <div>
                  <strong>Branded visuals</strong> — short, high-quality content
                  made specifically for social platforms.
                </div>
              </li>
            </FadeIn>
            <FadeIn delay={0.35}>
              <li className="leading-relaxed flex items-start">
                <span className="text-soft-white mr-3">→</span>
                <div>
                  <strong>Consistent posting</strong> — I&apos;ll manage your
                  page and keep your audience engaged.
                </div>
              </li>
            </FadeIn>
          </ul>
        </FadeIn>
      </section>

      {/* No Strings Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24">
        <FadeIn delay={0.3}>
          <div className="bg-soft-white/5 rounded-lg p-8 md:p-12">
            <h3 className="font-sora font-bold text-[clamp(20px,3vw,28px)] tracking-tight mb-6">
              No contracts. No hidden strings.
            </h3>
            <p className="text-[17px] md:text-[18px] leading-relaxed">
              Just clean, professional content that reflects the real presence
              of your business.
            </p>
          </div>
        </FadeIn>
      </section>

      {/* Requirements Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24">
        <FadeIn delay={0.4}>
          <h2 className="font-sora font-bold text-[clamp(24px,4vw,36px)] tracking-tight mb-6">
            I&apos;m looking for:
          </h2>
          <ul className="space-y-4 text-[17px] md:text-[18px]">
            <FadeIn delay={0.45}>
              <li className="leading-relaxed flex items-start">
                <span className="text-soft-white mr-3">→</span>
                <div>Established businesses with customers</div>
              </li>
            </FadeIn>
            <FadeIn delay={0.5}>
              <li className="leading-relaxed flex items-start">
                <span className="text-soft-white mr-3">→</span>
                <div>Physical Bay Area location</div>
              </li>
            </FadeIn>
          </ul>
        </FadeIn>
      </section>

      {/* CTA Section */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-16 md:py-24 text-center">
        <FadeIn delay={0.6}>
          <p className="text-[17px] md:text-[18px] leading-relaxed mb-8">
            If that&apos;s you, let&apos;s collaborate.
          </p>
          <div className="space-y-6">
            <div>
              <Link
                href="/inquiry"
                className="inline-block bg-soft-white text-soft-black px-8 py-4 rounded-lg text-[18px] md:text-[20px] font-bold hover:bg-pure-white transition-colors duration-200"
              >
                Send Inquiry
              </Link>
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

      {/* Back to Home */}
      <section className="max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-8">
        <FadeIn delay={0.7}>
          <Link
            href="/"
            className="inline-block text-sm opacity-50 hover:opacity-70 transition-opacity duration-200"
          >
            ← Back to Voro Lab
          </Link>
        </FadeIn>
      </section>

      {/* Footer */}
      <Footer navDelay={0.8} copyrightDelay={0.9} />
    </main>
  );
}
