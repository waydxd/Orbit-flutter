**Summary of FYP Proposal: Orbit - An Intelligent Calendar and Planning Solution Powered by AI**

**Team**: CHAN Wing Yu, LEUNG Wing Yan Winnie, WU Zijing, YAU Ho Yin  
**Advisor**: Dr. Cecia Ki CHAN  
**Institution**: The Hong Kong University of Science and Technology, Department of Computer Science and Engineering  
**Submission Date**: September 12, 2025  
**Project Period**: 2025-2026  

---

### **Overview**
Orbit is a smart calendar mobile app designed to address the inefficiencies of traditional calendar applications by integrating AI-driven features for personalized and proactive time management. The app targets individual users struggling with balancing work, leisure, and self-care in a hyper-connected world. Unlike conventional tools, Orbit leverages user preferences, behavioral patterns, and advanced AI to provide intuitive scheduling, task prioritization, and context-aware recommendations.

---

### **Objectives**
1. **User-Friendly Interface**: Deliver an intuitive interface with multi-view displays (day, week, month) and support for natural language input and OCR-based event extraction to reduce manual effort.  
2. **Personalized Recommendations**: Use historical data to suggest optimal time slots, prioritize tasks, and adapt to user routines, minimizing decision fatigue.  
3. **Conversational AI Assistance**: Integrate a chatbot for natural language interaction to manage schedules, resolve conflicts, and suggest optimal planning strategies.  
4. **Proactive Planning**: Implement predictive algorithms to anticipate user needs, recommend buffer times, and optimize productivity through pattern recognition.

---

### **Literature Survey**
The survey compares existing calendar, planner, and photo-sharing apps:  
- **Calendar Apps**:  
  - **Apple Calendar**: Simple, iCloud-integrated, but limited on non-Apple platforms and lacks AI-driven features.  
  - **Google Calendar**: Free, collaborative, with Gemini-driven suggestions, but requires a Google account and raises privacy concerns.  
  - **Fantastical**: Premium, feature-rich with natural language input, but costly ($4.75/month) and complex for casual users.  
- **Planner Apps**:  
  - **Todoist**: Simple task management with gamified productivity, but lacks robust calendar integration.  
  - **TickTick**: Multifaceted with habit tracking and calendar integration, but feature-heavy for some users.  
  - **Notion**: Highly customizable for teams, but has a steep learning curve and basic calendar functionality.  
- **Photo/Location Apps**:  
  - **Nothing OS Essential Space**: AI-powered note-taking, but lacks scheduling or cross-platform support.  
  - **Journey**: Multimedia journaling with AI prompts, but not designed for scheduling.  
  - **BeReal**: Focuses on social sharing, not productivity or planning.  

**Gap Identified**: Existing solutions lack a unified, AI-driven, adaptive platform combining intelligent scheduling, proactive planning, and personalization. Orbit aims to fill this gap.

---

### **Methodology**
#### **System Architecture**
Orbit uses a distributed architecture with three layers:  
1. **Frontend**: Built with Flutter/Dart for cross-platform mobile support, featuring a neumorphic UI (preferred by 70% of survey respondents) with multiple calendar views and natural language/image input.  
2. **Backend**: Modular microservices in Golang for performance, with Python-based AI services. Includes API Gateway, Authentication, Calendar, Intelligence, Integration, and Location services.  
3. **Data Layer**:  
   - PostgreSQL for structured data (events, user profiles).  
   - MongoDB for unstructured data and vector embeddings.  
   - Redis for caching.  
   - Object storage for user-generated content.  

#### **AI/ML Module**
- **Semantic Intake**: Processes text, voice, and OCR inputs using DistilBERT for parsing and Sentence-BERT for topic classification.  
- **Generative Reasoning**: Uses Gemini API for contextual suggestions (e.g., weather-based attire) and LangChain for conversational planning. TensorFlow Recommenders powers location suggestions.  

#### **Proposed Features**
- **Core**: User authentication (JWT), task management, event countdowns, basic calendar functions with holiday integration.  
- **AI-Driven**: Habit tracking (K-means clustering), natural language input, AI scheduling suggestions, chatbot planning, and OCR-based task creation.  
- **Extra**: Hashtag/topic marking, location tracking, special event display (e.g., holidays, anniversaries).  

#### **Implementation**
- **Frontend**: Flutter with MVVM architecture, Riverpod/Bloc for state management, and offline support via Hive/SQLite.  
- **Backend**: Golang microservices with REST/gRPC, integrated with Gemini API, Google Maps, and email services.  
- **AI**: Python-based with DistilBERT, Sentence-BERT, TensorFlow Recommenders, and vLLM for LLM hosting.  
- **Storage**: PostgreSQL, MongoDB, Redis, and cloud object storage.  

#### **Development & DevOps**
- **Methodology**: Modular monolith transitioning to microservices for scalability.  
- **Quality Assurance**: Automated linting, pre-commit hooks, and continuous profiling.  
- **CI/CD**: Automated builds, tests, and blue-green deployments using Docker and HKUST’s academic cloud.  
- **Repositories**: Separate GitHub repos for frontend, backend, AI, and deployment configs.  

---

### **Testing**
1. **Unit Testing**: Tests core logic, NLP, OCR, and AI recommendations with mock data and edge cases.  
2. **Integration Testing**: Verifies module interactions (e.g., database, NLP, AI assistant).  
3. **User Acceptance Testing (UAT)**: Public survey evaluated UI, UX, and feature necessity, confirming high-priority features like event countdowns.  
4. **Performance & Security**: Measures responsiveness, stability, and data protection through vulnerability assessments.

---

### **Evaluation**
- **AI/ML Models**: Assessed using accuracy, precision, and recall for NLP and recommendation systems.  
- **Comparison**: Orbit outperforms Google/Apple Calendar in multi-modal input, proactive AI, and personalization.  

---

### **Project Planning**
#### **Division of Labor**
- **CHAN Wing Yu**: Leads backend, architecture, database design, and deployment.  
- **LEUNG Wing Yan Winnie**: Leads AI/ML, documentation, and system integration.  
- **WU Zijing**: Leads frontend, UI/UX design, and testing.  
- **YAU Ho Yin**: Leads UI/UX, testing, and comparison with existing solutions.  

#### **Timeline (Gantt Chart)**
- **Jun–Sep 2025**: Research, literature survey, feasibility study, and design.  
- **Oct–Dec 2025**: Implementation of frontend, backend, and AI modules.  
- **Jan–Feb 2026**: Testing (unit, integration, UAT, performance/security).  
- **Mar–Apr 2026**: Evaluation, deployment, documentation, and presentation.  

---

### **Hardware & Software**
#### **Hardware**
- **Mobile Devices**: Android 14/iOS 18 smartphones (e.g., Pixel 9a, iPhone 16 Pro).  
- **Laptops/PCs**: MacBook Air (M3), ThinkPad X1 Carbon for development.  
- **Workstation**: Custom desktops with GPUs (AMD Radeon RX 6700 XT, NVIDIA RTX 5060) for AI training.  

#### **Software**
- Free tools: VSCode, Android Studio, MongoDB, PostgreSQL, Redis, Figma, Golang, Python, Flutter/Dart, vLLM, PyTorch, TensorFlow, scikit-learn, Transformers, LangChain-Go.  
- **Third-Party Services**:  
  - HKUST CSE Compute/VM: Free for students.  
  - Gemini API: Free tier + paid ($0.30–$15/1M tokens).  
  - Google Maps API: 10,000 free calls/month.  
  - Resend Email API: Free for 3,000 emails/month.  

---

### **Meeting Minutes (May–Aug 2025)**
- **1st (May 30)**: Brainstormed AI-enabled mobile app ideas, defined team roles.  
- **2nd (Jun 14)**: Completed literature review, identified market gaps, and finalized project concept.  
- **3rd (Jun 25)**: Selected Flutter, Golang, PostgreSQL; planned AI components.  
- **4th (Jul 10)**: Evaluated technical stack, prioritized features, and planned UI-first prototyping.  
- **5th (Jul 23)**: Refined frontend/backend workflows and testing approach.  
- **6th (Aug 4)**: Defined Flutter architecture, AI integration, and system diagrams.  
- **7th (Aug 22)**: Finalized AI features, backend microservices, and testing plans.  

---

### **Conclusion**
Orbit aims to revolutionize time management by combining intuitive design, AI-driven personalization, and proactive planning in a single mobile app. By addressing the limitations of existing tools through advanced AI features and a user-centric approach, Orbit offers a seamless, efficient, and adaptive scheduling experience. The project leverages modern technologies and a robust development strategy to deliver a scalable, secure, and innovative solution by April 2026.