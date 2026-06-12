<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:4c1d95,50:6d28d9,100:8b5cf6&height=220&section=header&text=Enzo%20Palmisano&fontSize=48&fontColor=ffffff&animation=fadeIn&fontAlignY=35&desc=Backend%20Engineer%20%E2%80%A2%20AI%20Specialist%20%E2%80%A2%20Product-Minded%20Builder&descAlignY=55&descSize=18" width="100%" alt="Header banner" />

<a href="https://github.com/e-palmisano">
  <img src="https://readme-typing-svg.demolab.com/?font=Fira+Code&weight=600&size=22&duration=3000&pause=800&color=8B5CF6&center=true&vCenter=true&width=650&lines=Backend+Engineer+%26+AI+Specialist;Generative+AI+%26+LLM+Systems;Native+macOS+%26+Full+Stack+Development;Building+Reliable+Enterprise+Software" alt="Typing animation" />
</a>

<br/>

<img src="https://img.shields.io/badge/Focus-Computer_Science_%26_AI-6d28d9?style=flat-square&logo=googlescholar&logoColor=white" alt="Academic focus" />
<img src="https://img.shields.io/badge/📍_Location-Bologna,_Italy-4c1d95?style=flat-square" alt="Location" />

<br/><br/>

<a href="https://e-palmisano.github.io">
  <img src="https://img.shields.io/badge/Portfolio-8b5cf6?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Portfolio" />
</a>
<a href="https://www.linkedin.com/in/enzo-palmisano-b16363147/">
  <img src="https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn" />
</a>
<a href="mailto:e.palmisano@reply.it">
  <img src="https://img.shields.io/badge/Email-6366f1?style=for-the-badge&logo=gmail&logoColor=white" alt="Email" />
</a>
<a href="https://github.com/e-palmisano">
  <img src="https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub" />
</a>

<br/><br/>

<img src="https://komarev.com/ghpvc/?username=e-palmisano&style=flat-square&color=8b5cf6&label=Profile+Views" alt="Profile views" />
<a href="https://github.com/e-palmisano?tab=followers">
  <img src="https://img.shields.io/github/followers/e-palmisano?style=flat-square&logo=github&color=6d28d9&label=Followers" alt="Followers" />
</a>
<a href="https://github.com/e-palmisano?tab=repositories">
  <img src="https://img.shields.io/github/stars/e-palmisano?style=flat-square&logo=github&color=8b5cf6&label=Stars" alt="Stars" />
</a>

</div>

---

## 🧭 About

Backend Engineer & AI Specialist at **Blue Reply**, working on enterprise software for the insurance domain. I design and ship backend systems and Generative AI solutions — from LLM-powered assistants to the APIs and data layers that make them production-ready.

- ⚙️ **Software Engineering** — clean architecture, protocol-oriented design, test-first development, zero-dependency native apps
- 🤖 **AI / ML** — Generative AI, LLM integration, RAG pipelines, and agentic workflows for enterprise use cases
- 🧱 **Full Stack** — backend services, REST APIs, data persistence, and the frontend surfaces that consume them
- 🚀 **Product Engineering Mindset** — I ship complete products: packaging, distribution (Homebrew), CI/CD, and documentation included

**Open To:** collaboration on open-source tooling, AI engineering projects, and conversations about native macOS development.

---

## 🛠️ Tech Stack

<div align="center">

**Languages**

<img src="https://skillicons.dev/icons?i=python,swift,ts,js,java,bash" alt="Languages" />

**Frontend**

<img src="https://skillicons.dev/icons?i=react,html,css,tailwind" alt="Frontend" />

**Backend & Databases**

<img src="https://skillicons.dev/icons?i=fastapi,nodejs,spring,postgres,mongodb,redis" alt="Backend and databases" />

**Cloud, DevOps & Tooling**

<img src="https://skillicons.dev/icons?i=aws,docker,git,github,githubactions,linux,apple" alt="Cloud, DevOps and tooling" />

</div>

---

## 🤖 AI / ML Expertise

<div align="center">

| Domain | Proficiency | Details |
|:-------|:-----------:|:--------|
| **Generative AI & LLMs** | ▰▰▰▰▰▱ | LLM-powered assistants, prompt engineering, model integration in enterprise products |
| **RAG Systems** | ▰▰▰▰▰▱ | Retrieval pipelines, embeddings, vector search, grounded enterprise knowledge bases |
| **Agentic AI** | ▰▰▰▰▱▱ | Tool-using agents, coding-agent harnesses, multi-step orchestration |
| **NLP** | ▰▰▰▰▱▱ | Text extraction, transcription pipelines, document understanding |
| **MLOps & Serving** | ▰▰▰▱▱▱ | API-first model serving, evaluation loops, CI for ML-backed services |

</div>

---

## 🚀 Featured Projects

<details>
<summary><b>🔒 Vigil — Native macOS Input Lock</b></summary>

<br/>

A lightweight native macOS utility that blocks all physical input system-wide while keeping long-running workloads — builds, renders, downloads — fully active.

| | |
|:--|:--|
| **Stack** | Swift 6, AppKit, CGEventTap, XcodeGen |
| **Scale** | Multi-display with hot-plug detection; system-wide HID-level event interception |
| **Performance** | Fully native, zero external dependencies, no telemetry, no network calls |
| **Security** | Accessibility-gated input blocking, Touch ID unlock with password fallback, crash-recovery lock restore |
| **Impact** | Shipped end-to-end: signed releases, Homebrew cask distribution, CI pipeline |
| **Repository** | [e-palmisano/Vigil](https://github.com/e-palmisano/Vigil) |

Vigil intercepts keyboard and mouse events at the HID level — the only macOS API that blocks input before it reaches any application. The architecture is protocol-oriented (every service behind a `*Protocol` interface with test mocks), test-first, and deliberately dependency-free.

</details>

<details>
<summary><b>🧩 macos-dev — Claude Code Plugin for Native macOS Development</b></summary>

<br/>

A Claude Code plugin for native macOS development with SwiftUI, AppKit, and Liquid Glass, bundling curated Apple Developer documentation for agentic coding workflows.

| | |
|:--|:--|
| **Stack** | JavaScript, Claude Code plugin system, curated Apple Developer docs |
| **Scale** | Covers SwiftUI, AppKit, and modern macOS design-system APIs |
| **Performance** | Local documentation bundle — zero network latency for doc lookups |
| **Security** | Read-only documentation tooling, no credentials or external calls |
| **Impact** | Makes AI coding agents reliable on niche, fast-moving native macOS APIs |
| **Repository** | [e-palmisano/macos-dev](https://github.com/e-palmisano/macos-dev) |

Built from the experience of developing Vigil with AI pair programmers: agents are only as good as the context they're given, so this plugin gives them first-class, curated platform documentation.

</details>

<details>
<summary><b>🍺 homebrew-tap — Distribution Infrastructure</b></summary>

<br/>

A Homebrew tap providing one-command installation for my macOS tools.

| | |
|:--|:--|
| **Stack** | Ruby, Homebrew cask DSL, GitHub Releases |
| **Scale** | Single tap serving all published tools (`brew install --cask e-palmisano/tap/vigil`) |
| **Performance** | Automated cask updates tied to the release pipeline |
| **Security** | Checksummed artifacts pulled from signed GitHub Releases |
| **Impact** | Frictionless install path — from repository to running app in one command |
| **Repository** | [e-palmisano/homebrew-tap](https://github.com/e-palmisano/homebrew-tap) |

Shipping a product means owning distribution too: this tap closes the loop between CI builds, GitHub Releases, and the end user's machine.

</details>

<details>
<summary><b>🏢 Enterprise Generative AI Assistant — Blue Reply</b></summary>

<br/>

A Generative AI assistant developed at Blue Reply for the enterprise insurance domain.

| | |
|:--|:--|
| **Stack** | Python, LLM APIs, RAG pipeline |
| **Scale** | Enterprise knowledge base for insurance workflows |
| **Performance** | Grounded retrieval to keep responses accurate and auditable |
| **Security** | Enterprise data-handling and access controls |
| **Impact** | Brought LLM capabilities into day-to-day enterprise workflows |
| **Repository** | Private — enterprise project |

Details are confidential; happy to discuss the architecture patterns (retrieval, grounding, evaluation) in general terms.

</details>

---

## 💼 Experience

### Backend Engineer & AI Specialist · **Blue Reply** (Blue Insurance IT)

**2024 — Present** · Bologna, Italy

Engineering backend systems and Generative AI solutions for the enterprise insurance domain.

- Design and develop backend services and REST APIs for insurance-domain products
- Build Generative AI solutions — LLM integration, RAG pipelines, and AI-assisted workflows
- Contribute across the stack, from data persistence to the interfaces consuming the APIs
- Apply test-driven development and clean-architecture practices in an enterprise delivery context

<img src="https://img.shields.io/badge/Python-3776AB?style=flat-square&logo=python&logoColor=white" alt="Python" /> <img src="https://img.shields.io/badge/Generative_AI-8b5cf6?style=flat-square&logo=openaigym&logoColor=white" alt="Generative AI" /> <img src="https://img.shields.io/badge/REST_APIs-6366f1?style=flat-square&logo=fastapi&logoColor=white" alt="REST APIs" /> <img src="https://img.shields.io/badge/RAG-6d28d9?style=flat-square&logo=databricks&logoColor=white" alt="RAG" /> <img src="https://img.shields.io/badge/SQL-4c1d95?style=flat-square&logo=postgresql&logoColor=white" alt="SQL" />

---

## 🏆 Achievements

<div align="center">

| Recognition | Details |
|:------------|:--------|
| 🚀 **Shipped a complete native macOS product** | Vigil — from architecture to signed releases, CI, and Homebrew distribution |
| 🧩 **Published developer tooling for AI agents** | macos-dev Claude Code plugin with curated Apple Developer documentation |
| 🍺 **Maintainer of a public Homebrew tap** | One-command install pipeline for all published tools |
| 🤖 **Enterprise Generative AI delivery** | LLM-powered assistant built for the insurance domain at Blue Reply |

</div>

---

## 📜 Certifications

<div align="center">

**AWS**

<img src="https://img.shields.io/badge/AWS-Add_your_certification-FF9900?style=for-the-badge&logo=task&logoColor=white" alt="AWS certification placeholder" />

**Oracle**

<img src="https://img.shields.io/badge/Oracle-Add_your_certification-F80000?style=for-the-badge&logo=oracle&logoColor=white" alt="Oracle certification placeholder" />

**Cisco**

<img src="https://img.shields.io/badge/Cisco-Add_your_certification-1BA0D7?style=for-the-badge&logo=cisco&logoColor=white" alt="Cisco certification placeholder" />

</div>

---

## ⚔️ Coding Profiles

<div align="center">

<a href="https://leetcode.com/u/e-palmisano/">
  <img src="https://img.shields.io/badge/LeetCode-FFA116?style=for-the-badge&logo=leetcode&logoColor=white&labelColor=1a1a2e" alt="LeetCode" height="40" />
</a>
&nbsp;
<a href="https://www.geeksforgeeks.org/user/e-palmisano/">
  <img src="https://img.shields.io/badge/GeeksforGeeks-2F8D46?style=for-the-badge&logo=geeksforgeeks&logoColor=white&labelColor=1a1a2e" alt="GeeksforGeeks" height="40" />
</a>
&nbsp;
<a href="https://www.hackerrank.com/profile/e_palmisano">
  <img src="https://img.shields.io/badge/HackerRank-00EA64?style=for-the-badge&logo=hackerrank&logoColor=white&labelColor=1a1a2e" alt="HackerRank" height="40" />
</a>
&nbsp;
<a href="https://www.codechef.com/users/e_palmisano">
  <img src="https://img.shields.io/badge/CodeChef-5B4638?style=for-the-badge&logo=codechef&logoColor=white&labelColor=1a1a2e" alt="CodeChef" height="40" />
</a>

</div>

---

## 📊 GitHub Analytics

<div align="center">

<img src="https://github-readme-stats.vercel.app/api?username=e-palmisano&show_icons=true&hide_border=true&bg_color=0d1117&title_color=8b5cf6&icon_color=8b5cf6&text_color=c9d1d9&ring_color=6d28d9&count_private=true" height="170" alt="GitHub stats" />
<img src="https://github-readme-stats.vercel.app/api/top-langs/?username=e-palmisano&layout=compact&hide_border=true&bg_color=0d1117&title_color=8b5cf6&text_color=c9d1d9&langs_count=8" height="170" alt="Top languages" />

<br/><br/>

<img src="https://streak-stats.demolab.com/?user=e-palmisano&hide_border=true&background=0d1117&ring=8b5cf6&fire=a78bfa&currStreakLabel=8b5cf6&sideLabels=c9d1d9&currStreakNum=ffffff&sideNums=ffffff&dates=8b949e" alt="GitHub streak" />

</div>

---

## 🏅 GitHub Trophies

<div align="center">

<img src="https://github-profile-trophy.vercel.app/?username=e-palmisano&theme=dracula&no-frame=true&no-bg=true&column=7&margin-w=8&margin-h=8" alt="GitHub trophies" />

</div>

---

## 📈 Contribution Activity

<div align="center">

<img src="https://github-readme-activity-graph.vercel.app/graph?username=e-palmisano&bg_color=0d1117&color=a78bfa&line=6366f1&point=8b5cf6&area=true&area_color=4c1d95&hide_border=true" width="95%" alt="Contribution activity graph" />

</div>

---

## 🐍 Contribution Snake

<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="https://raw.githubusercontent.com/e-palmisano/e-palmisano/output/github-contribution-grid-snake-dark.svg" />
  <source media="(prefers-color-scheme: light)" srcset="https://raw.githubusercontent.com/e-palmisano/e-palmisano/output/github-contribution-grid-snake.svg" />
  <img src="https://raw.githubusercontent.com/e-palmisano/e-palmisano/output/github-contribution-grid-snake-dark.svg" alt="Contribution snake animation" />
</picture>

</div>

---

## 🎯 Current Focus

```yaml
learning:
  - Swift 6 strict concurrency and modern AppKit/SwiftUI patterns
  - Agentic AI architectures and coding-agent tooling

building:
  - Vigil — native macOS input-lock utility
  - macos-dev — Claude Code plugin for native macOS development

exploring:
  - LLM evaluation and grounding techniques for enterprise RAG
  - Developer-experience tooling for AI-assisted workflows

open_to:
  - Open-source collaboration
  - AI engineering and native macOS conversations
```

---

## 🤝 Connect

<div align="center">

<a href="mailto:e.palmisano@reply.it">
  <img src="https://img.shields.io/badge/Email-e.palmisano@reply.it-6366f1?style=for-the-badge&logo=gmail&logoColor=white" alt="Email" />
</a>
<br/>
<a href="https://www.linkedin.com/in/enzo-palmisano-b16363147/">
  <img src="https://img.shields.io/badge/LinkedIn-Enzo_Palmisano-0077B5?style=for-the-badge&logo=linkedin&logoColor=white" alt="LinkedIn" />
</a>
<br/>
<a href="https://github.com/e-palmisano">
  <img src="https://img.shields.io/badge/GitHub-e--palmisano-181717?style=for-the-badge&logo=github&logoColor=white" alt="GitHub" />
</a>
<br/>
<a href="https://e-palmisano.github.io">
  <img src="https://img.shields.io/badge/Portfolio-Visit-8b5cf6?style=for-the-badge&logo=googlechrome&logoColor=white" alt="Portfolio" />
</a>

</div>

---

<div align="center">

*Good tools make good work possible.*

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:8b5cf6,50:6d28d9,100:4c1d95&height=120&section=footer" width="100%" alt="Footer banner" />

</div>
