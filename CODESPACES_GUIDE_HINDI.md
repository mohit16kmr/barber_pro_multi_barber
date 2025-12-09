# GitHub Codespaces par BarberPro Project Chalana

## Codespaces kya hai?
Browser se VS Code use kar sakte ho, kisi setup ki zarorat nahi. Bas GitHub account chahiye.

## Step-by-Step Guide

### 1. GitHub par Project Push Karo
```bash
git remote add origin https://github.com/YOUR_USERNAME/newbarberproject.git
git branch -M main
git push -u origin main
```

### 2. Codespaces Open Karo
- GitHub par apna repository kholo
- Green **"Code"** button par click karo
- **"Codespaces"** tab select karo
- **"Create codespace on main"** click karo
- Browser me VS Code khul jayega (2-3 minutes wait karo setup ke liye)

### 3. Setup Automatically Ho Jayega
`.devcontainer/devcontainer.json` automatically:
- Flutter install karega
- Dependencies fetch karega (`flutter pub get`)
- Extensions setup karega

### 4. App Run Karo

#### Customer App
```bash
flutter run -d chrome -t lib/main_customer.dart
```

#### Barber App
```bash
flutter run -d chrome -t lib/main_barber.dart
```

#### Admin App
```bash
flutter run -d chrome -t lib/main_admin.dart
```

App browser me khul jayega!

### 5. Physical Phone par Chalana (Optional)
Agar apka phone connected hai:
```bash
flutter devices
flutter run -d R9ZWA0CKYSP -t lib/main_customer.dart
```

## Codespaces ke Fayede
✅ Kisi bhi machine se code kar sakte ho  
✅ Sab setup already installed hai  
✅ Internet connection bas chahiye  
✅ VS Code ke saath GitHub integration  
✅ Free 120 CPU hours/month (personal use ke liye)  

## Storage Tips
- Codespaces me 32GB storage milta hai
- Regular `git push` karo backup ke liye
- Large files `.gitignore` me daalo

## Agar Kuch Problem Aaye
```bash
# Flutter doctor check karo
flutter doctor

# Dependencies refresh karo
flutter clean
flutter pub get

# Cache clear karo
flutter clean
rm -rf build/
```

## Codespaces Band Karna
- Automatically band ho jaata hai 30 minutes inactivity ke baad
- Manual band: GitHub → Codespaces → Stop codespace

Koi question ho to bata! 🚀
