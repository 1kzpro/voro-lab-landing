import { FadeIn } from "@/components/FadeIn";
import { Navigation } from "@/components/Navigation";

interface FooterProps {
  navDelay?: number;
  copyrightDelay?: number;
  className?: string;
}

export function Footer({
  navDelay = 0.5,
  copyrightDelay = 0.6,
  className = "",
}: FooterProps) {
  return (
    <footer
      className={`max-w-[880px] mx-auto px-6 md:px-16 lg:px-24 py-8 md:py-12 ${className}`}
    >
      <Navigation delay={navDelay} className="mb-8" />
      <FadeIn delay={copyrightDelay}>
        <small className="block text-center text-sm opacity-50">
          © 2025 Voro Lab — Bay Area. Real content. Real presence.
        </small>
      </FadeIn>
    </footer>
  );
}
