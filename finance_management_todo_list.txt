## ✅ Finance Management System – To-Do List (Realistic Progress)

### 🎨 1. UI Implementation From Figma
- [x] Review Figma for all pages and navigation flow  
- [ ] Convert all key screens to Flutter widgets:
  - [x] Dashboard/Home  
  - [ ] Add Transaction screen  
  - [ ] Transactions list  
  - [ ] Add Goal screen  
  - [ ] Goals summary screen  
  - [ ] Budget & Insights screen  
- [ ] Implement routing between screens (`Navigator` or `GoRouter`)  
- [ ] Create reusable components (buttons, cards, inputs)

### 🔧 2. Firebase Setup (Already Done)
- [x] Create Firebase project  
- [x] Connect Android/iOS app to Firebase  
- [x] Download & add `google-services.json` / `GoogleService-Info.plist`  
- [x] Add Firebase packages (`firebase_core`, `firebase_auth`, `cloud_firestore`)  
- [x] Initialize Firebase in `main.dart`  

### 🔐 3. User Authentication
- [x] Create login/signup UI  
- [ ] Connect UI to Firebase Auth (email/password or Google)  
- [ ] Redirect authenticated users to dashboard  
- [ ] Handle auth state on app start  
- [ ] Secure user-specific data access (with Firestore rules)

### 📦 4. Firestore Data Modeling
Design Firestore collections and structure:
- [ ] `/users/{userId}` — name, balance, budget  
- [ ] `/users/{userId}/transactions/{transactionId}` — amount, type, category, date  
- [ ] `/users/{userId}/goals/{goalId}` — name, target, progress, deadline  
- [ ] (Optional) `/categories/{categoryId}` — static or user-defined categories  

### 💻 5. Frontend + Backend Integration
- [ ] Hook up Add Transaction form → Firestore  
- [ ] Show list of transactions (filtered by category/date)  
- [ ] Hook up Add Goal form → Firestore  
- [ ] Display goals with progress  
- [ ] Build dashboard with totals & charts  

### ✨ 6. Additional Features
- [ ] Edit/delete transactions and goals  
- [ ] Category selector with icons/colors  
- [ ] Budget progress indicators  
- [ ] Summary reports by month/week  
- [ ] Notifications (optional)

### 🧪 7. Polish and Testing
- [ ] Input validation and error handling  
- [ ] Loading states and success/error toasts  
- [ ] Dark mode (optional)  
- [ ] Responsive layout for different devices  
- [ ] Optimize Firestore usage (indexes, reads, rules)

### 🚀 8. Final Touches & Deployment
- [ ] Add splash screen & app icon  
- [ ] Test full user journey  
- [ ] Finalize Firestore Security Rules  
- [ ] Prepare store listing or APK for release  
