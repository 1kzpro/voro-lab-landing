import { FadeIn } from "@/components/FadeIn";
import Link from "next/link";

interface NavigationProps {
  delay?: number;
  className?: string;
}

export function Navigation({ delay = 0, className = "" }: NavigationProps) {
  return (
    <FadeIn delay={delay} className={className}>
      <nav className="flex flex-wrap justify-center gap-6 md:gap-8">
        <Link
          href="/"
          className="text-sm opacity-50 hover:opacity-70 transition-opacity duration-200"
        >
          Home
        </Link>
        <Link
          href="/offer"
          className="text-sm opacity-50 hover:opacity-70 transition-opacity duration-200"
        >
          No-Cost Content
        </Link>
        <Link
          href="/inquiry"
          className="text-sm opacity-50 hover:opacity-70 transition-opacity duration-200"
        >
          Get In Touch
        </Link>
        <a
          href="https://instagram.com/voro.lab"
          target="_blank"
          rel="noopener noreferrer"
          className="text-sm opacity-50 hover:opacity-70 transition-opacity duration-200"
        >
          @voro.lab
        </a>
      </nav>
    </FadeIn>
  );
}
