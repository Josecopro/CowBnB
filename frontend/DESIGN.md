# 🎨 AgroTerra Design System — Flutter + Dart + Agents

---

## 1. 📌 Purpose

Este documento define un **Design System programable** optimizado para:

* Generación automática de UI por agentes
* Consistencia en Flutter (`Material 3`)
* Escalabilidad modular
* Minimizar decisiones ambiguas en UI

---

## 2. 🧠 Core Principle (CRÍTICO PARA AGENTES)

> ⚠️ **Regla absoluta:**
> El agente **NO puede inventar estilos**.
> Debe usar exclusivamente los tokens definidos aquí.

---

## 3. 🎨 Design Tokens (Fuente Única de Verdad)

### 3.1 Color Tokens

```dart
class AppColors {
  static const primary = Color(0xFF5CA275);
  static const primaryDark = Color(0xFF4A8A62);
  static const primaryLight = Color(0xFF7BBF93);

  static const secondary = Color(0xFF577763);

  static const success = Color(0xFF51CC7F);
  static const error = Color(0xFFD64545);
  static const warning = Color(0xFFE6A23C);

  static const textPrimary = Color(0xFF454D48);
  static const textSecondary = Color(0xFF8A918D);
  static const border = Color(0xFFDADDD9);
}
```

---

### 3.2 Spacing Tokens (8pt grid)

```dart
class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}
```

---

### 3.3 Radius Tokens

```dart
class AppRadius {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
}
```

---

### 3.4 Typography Tokens

```dart
class AppTextStyles {
  static const headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}
```

---

## 4. 🎯 ThemeData (Integración Flutter)

```dart
ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      error: AppColors.error,
      onError: Colors.white,
      surface: Colors.white,
      onSurface: AppColors.textPrimary,
    ),

    textTheme: const TextTheme(
      headlineLarge: AppTextStyles.headline,
      bodyMedium: AppTextStyles.body,
      labelMedium: AppTextStyles.label,
    ),
  );
}
```

---

## 5. 🧱 Component System (Agent-Driven)

### 5.1 Button Component

#### API

```dart
enum ButtonVariant { primary, secondary, outlined }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
  });
}
```

---

#### Implementación base

```dart
Color _getColor(ButtonVariant variant) {
  switch (variant) {
    case ButtonVariant.primary:
      return AppColors.primary;
    case ButtonVariant.secondary:
      return AppColors.secondary;
    case ButtonVariant.outlined:
      return Colors.transparent;
  }
}
```

---

### 5.2 Card Component

```dart
class AppCard extends StatelessWidget {
  final Widget child;

  const AppCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
```

---

### 5.3 Input Component

```dart
class AppInput extends StatelessWidget {
  final String hint;

  const AppInput({required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
```

---

## 6. 🤖 Agent Rules (MUY IMPORTANTE)

### 6.1 Generación de UI

El agente debe:

1. Usar SOLO componentes definidos (`AppButton`, `AppCard`, etc.)
2. NO usar `Container` directo si existe componente equivalente
3. NO hardcodear colores
4. Usar `AppSpacing` siempre

---

### 6.2 Jerarquía de UI

Orden obligatorio:

```
Screen
 ├── Scaffold
 │    ├── AppBar
 │    └── Body
 │         ├── AppCard
 │         ├── AppInput
 │         └── AppButton
```

---

### 6.3 Naming Convention

```
[feature]_[component]_[variant]
```

Ejemplo:

```
login_button_primary
dashboard_card_stats
```

---

## 7. 📐 Layout Rules

* Padding global: `AppSpacing.lg`
* Separación vertical: `AppSpacing.md`
* Máximo ancho recomendado: `600px` (mobile-first)

---

## 8. 🎬 Animations

```dart
const defaultAnimationDuration = Duration(milliseconds: 200);
```

Reglas:

* Siempre usar animaciones suaves
* Nunca animaciones > 300ms

---

## 9. ♿ Accesibilidad

* Texto mínimo: 14px
* Botones mínimo: 48px altura
* Contraste obligatorio

---

## 10. 🧩 Ejemplo Generado (Referencia para Agentes)

```dart
class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("AgroTerra")),
      body: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppCard(
              child: Column(
                children: [
                  Text("Welcome", style: AppTextStyles.headline),
                  SizedBox(height: AppSpacing.md),
                  AppInput(hint: "Enter name"),
                  SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: "Continue",
                    onPressed: () {},
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
```

---

## 11. 🚫 Anti-Patterns

❌ `Color(0xFFxxxxxx)` fuera de tokens
❌ `EdgeInsets.all(13)` (usar spacing)
❌ UI inconsistente
❌ Mezclar estilos inline

---

## 12. 🚀 Extensión futura

* Dark mode automático
* Soporte para responsive (tablet/web)
* Integración con generadores AI (LLM → Flutter UI)

---

## 13. ✅ Conclusión

Este sistema permite a un agente:

* Generar UI automáticamente
* Mantener consistencia perfecta
* Reducir errores de diseño
* Escalar rápidamente en Flutter

---
