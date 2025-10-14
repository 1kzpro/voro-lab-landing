# Voro Lab — One‑Page Website Copy & Style Guide

> **Tagline:** Real content. Real presence.  
> **Region:** Bay Area

---

## 1) Copy (ready to paste)

### Hero
```
VORO LAB
Real content. Real presence.
```

### Intro / About
```
Hi, I’m Kazybek — the person behind Voro Lab.

I create real, authentic social‑media content for Bay Area brands and businesses.
No stock footage, no fake energy — just your story, your people, and your presence brought to life through short, engaging videos and visuals.
```

### Service Line
```
→ Social media content production
→ Short‑form videos & photography
→ Monthly content days for local Bay Area businesses
```

### Call to Action
```
Let’s create something real together.
(334) 329‑9784
```

### Footer (optional)
```
© 2025 Voro Lab — Bay Area. Real content. Real presence.
```

---

## 2) Styling Notes (B/W minimal)

**Palette**
- Soft Black: `#121212` (backgrounds, dark sections)
- Soft White: `#F2F2F2` (default text on dark)
- Pure White: `#FFFFFF` (accents, hover on dark)
- Optional Hairline Gray: `#2A2A2A` (thin rules, borders)

**Typography**
- Headings / Brand: **Sora** (Bold 700–800 for “VORO LAB”)
- Body / UI: **Inter** (Regular 400, Medium 500)
- Tagline: Inter 400–500 (sentence case, tracking +0.02em)

**Sizing (web)**
- Hero Brand: clamp(36px, 6vw, 72px)
- Hero Tagline: clamp(16px, 2.4vw, 24px)
- Body Copy: 16–18px
- List Items: 16–18px
- Phone CTA: 20–22px, bold

**Layout**
- One column, generous spacing
- Section max‑width: 720–880px
- Page padding: 24–32px mobile, 64–96px desktop
- Left‑aligned copy; center the hero if desired

**Example Content Order**
1. Hero (centered)
2. Intro (left)
3. Services (left, short list)
4. CTA (centered phone)
5. Footer (tiny, low‑contrast)

**Accessibility**
- Contrast ratio ≥ 7:1 on text
- Line length 50–75 characters
- Line height 1.4–1.6 for paragraphs

---

## 3) Animation — Simple Fade‑In on Scroll

Keep motion minimal and classy to match the monochrome style.

### Concept
- Elements start slightly transparent and shifted down.
- As they enter the viewport, they fade to 100% and slide into place.
- Duration 300–500ms, easing `cubic-bezier(0.2, 0.8, 0.2, 1)`.

### CSS (vanilla)
```css
.reveal {
  opacity: 0;
  transform: translateY(12px);
  transition: opacity 420ms cubic-bezier(0.2, 0.8, 0.2, 1),
              transform 420ms cubic-bezier(0.2, 0.8, 0.2, 1);
  will-change: opacity, transform;
}
.reveal.is-visible {
  opacity: 1;
  transform: translateY(0);
}
```

### JS (IntersectionObserver)
```js
const els = document.querySelectorAll('.reveal');

const io = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.classList.add('is-visible');
      io.unobserve(entry.target); // reveal once
    }
  });
}, { rootMargin: '0px 0px -10% 0px', threshold: 0.1 });

els.forEach(el => io.observe(el));
```

### Tailwind (utility approach)
```html
<!-- Start hidden -->
<div class="opacity-0 translate-y-3 transition-all duration-500 ease-[cubic-bezier(0.2,0.8,0.2,1)] will-change-transform will-change-opacity"
     x-data x-intersect.once="$el.classList.remove('opacity-0','translate-y-3')">
  <!-- content -->
</div>
```
> If you’re not using Alpine/`x-intersect`, add a small script that removes those classes when elements enter the viewport (same idea as the IntersectionObserver above).

### Framer Motion (React option)
```jsx
<motion.div
  initial={{ opacity: 0, y: 12 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.2 }}
  transition={{ duration: 0.42, ease: [0.2, 0.8, 0.2, 1] }}
>
  {/* content */}
</motion.div>
```

**What to animate**
- Hero tagline, Intro paragraph, each Service line, CTA phone.
- Stagger children by 60–100ms for a subtle cascade.

---

## 4) Minimal HTML Skeleton (optional reference)
```html
<section class="hero reveal">
  <h1>VORO LAB</h1>
  <p>Real content. Real presence.</p>
</section>

<section class="intro reveal">
  <p>Hi, I’m Kazybek — the person behind Voro Lab.</p>
  <p>I create real, authentic social‑media content for Bay Area brands and businesses.
     No stock footage, no fake energy — just your story, your people, and your presence
     brought to life through short, engaging videos and visuals.</p>
</section>

<section class="services reveal">
  <ul>
    <li>→ Social media content production</li>
    <li>→ Short‑form videos & photography</li>
    <li>→ Monthly content days for local Bay Area businesses</li>
  </ul>
</section>

<section class="cta reveal">
  <p>Let’s create something real together.</p>
  <a href="tel:+13343299784">(334) 329‑9784</a>
</section>

<footer class="footer reveal">
  <small>© 2025 Voro Lab — Bay Area. Real content. Real presence.</small>
</footer>
```
