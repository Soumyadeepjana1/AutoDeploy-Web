# Learnora — Online Learning Platform 🎓

A premium, modern landing page for an online education startup, built with **HTML5 and CSS3 only**.
No JavaScript, no frameworks, no external UI libraries — just two files and a polished, glossy design.

Think glassmorphism cards, soft neumorphism touches, gradient glows, smooth animations, and a
vibrant blue → violet → white palette that feels like a real SaaS product website.

---

## ✨ Features

- **Sticky glass navigation** with a working CSS-only mobile burger menu
- **Animated hero** with floating glassmorphism info cards and a mock course player
- **6 course categories** with hover reveal effects
- **6 premium course cards** with thumbnail, instructor, rating, duration, students, price and CTA
- **"Why Choose Learnora"** feature grid (Expert Instructors, Practical Learning, Lifetime Access, Certificates)
- **Learning Journey** step flow: Discover → Learn → Practice → Achieve
- **Testimonials** with star ratings, gradient avatars and a highlighted featured review
- **Gradient call-to-action** banner and a full **footer** with quick links, categories, socials and newsletter form
- **Fully responsive**: desktop, tablet and mobile
- **Accessible**: semantic HTML, focus styles, reduced-motion support, ARIA labels
- **Lightweight**: zero dependencies, single stylesheet, inline SVG icons

---

## 📂 Project Structure

```
.
├── index.html    # Main entry point — all page sections (semantic HTML5)
├── style.css     # Complete design system: tokens, layout, animations, media queries
└── README.md     # This file
```

---

## 🗂️ Page Sections

| # | Section | Highlights |
|---|---------|-----------|
| 1 | Navigation | Logo, Home / Explore Courses / Categories / About, Login + Get Started, sticky glass bar |
| 2 | Hero | "Unlock Your Potential Through Learning." + dual CTAs, stats, floating glass cards |
| 3 | Categories | Web Development, Data Science, Cloud Computing, Cybersecurity, UI/UX Design, DevOps |
| 4 | Popular Courses | 6 course cards with rating, duration, students, price, Enroll Now |
| 5 | Why Choose Learnora | 4 benefit cards with icons |
| 6 | Learning Journey | Discover → Learn → Practice → Achieve |
| 7 | Testimonials | 3 student reviews with stars and avatars |
| 8 | Call To Action | "Start Your Learning Journey Today." + Get Started button |
| 9 | Footer | Logo, quick links, categories, social media, newsletter, copyright |

---

## 🚀 Getting Started

### Option 1 — Just open it

Double-click `index.html` (or drag it into your browser). That's it — everything works offline.

### Option 2 — Local web server

Any static server works:

```bash
# Python
python3 -m http.server 8080

# or Node
npx serve .
```

Then visit <http://localhost:8080>.

### Option 3 — Nginx inside Docker (as required)

No Dockerfile needed — mount the project folder into the official Nginx image:

```bash
docker run --rm -p 8080:80 \
  -v "$(pwd)":/usr/share/nginx/html:ro \
  nginx:alpine
```

Open <http://localhost:8080> and you should see the site served by Nginx.

<details>
<summary>Prefer a <code>docker-compose.yml</code>?</summary>

```yaml
services:
  web:
    image: nginx:alpine
    ports:
      - "8080:80"
    volumes:
      - ./:/usr/share/nginx/html:ro
```

```bash
docker compose up
```

</details>

---

## 🎨 Customization

All design tokens live at the top of `style.css` in the `:root` block:

```css
:root {
    --blue: #1d4ed8;      /* corporate blue      */
    --violet: #4338ca;    /* deep indigo         */
    --grad-primary: linear-gradient(135deg, #2563eb 0%, #1d4ed8 45%, #4338ca 100%);
    --glass-bg: linear-gradient(180deg, rgba(255, 255, 255, 0.86), rgba(255, 255, 255, 0.58) 48%, rgba(248, 250, 252, 0.66));  /* glossy glass panels */
    --radius-lg: 26px;    /* card corner radius  */
    /* ...shadows, fonts, spacing */
}
```

Change a token there and the whole site updates consistently.

**Common tweaks:**

| Want to… | Edit |
|----------|------|
| Change the color scheme | `--blue`, `--violet`, `--grad-primary` in `:root` |
| Adjust glass transparency | `--glass-bg` and `.glass` blur value |
| Make corners sharper/rounder | `--radius-sm/md/lg/xl` |
| Edit page content | Text directly inside `index.html` |
| Tune animations | `/* 13. Animations */` section at the bottom of `style.css` |

---

## 🛠️ Tech Notes

- **HTML5**: semantic elements (`header`, `nav`, `main`, `section`, `article`, `figure`, `footer`), inline SVG sprite for icons
- **CSS3**: Flexbox, Grid, `backdrop-filter` (glassmorphism), layered gradients, `box-shadow` (neumorphism/gloss), keyframe animations, CSS custom properties
- **Responsive breakpoints**: 1024px (stack hero, 2-col journey), 900px (mobile menu), 768px (single-col courses), 560px (compact mobile)
- **Mobile menu**: pure CSS checkbox hack — no JavaScript
- **Animations respect** `prefers-reduced-motion` for accessibility
- Tested on modern Chrome, Edge, Firefox and Safari (`-webkit-backdrop-filter` included)

---

## 📄 License

Free to use for personal and commercial projects. Attribution appreciated but not required.

**Generated for the Learnora project.** Happy learning! 🚀
