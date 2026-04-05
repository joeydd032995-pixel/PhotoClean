# iOS HIG Compliance Checklist

## Touch Targets

- **Minimum 44×44 pt** for all tappable/interactive elements (buttons, list rows, icons)
- Inline icons used as buttons (`Image(systemName:)`) without explicit `.frame(width:height:)` — add `.contentShape(Rectangle())` + frame
- Custom gesture recognizers covering regions smaller than 44pt
- **Fix pattern**:
  ```swift
  Button { action() } label: {
      Image(systemName: "trash")
  }
  .frame(width: 44, height: 44)
  .contentShape(Rectangle())
  ```

## Safe Areas

- Content must not render under the Dynamic Island, home indicator, or status bar without intent
- `.ignoresSafeArea()` / `.edgesIgnoringSafeArea()` must be deliberate (background fills only, never interactive content)
- Sheets and full-screen covers: verify bottom buttons aren't clipped on devices with home indicator
- Keyboard avoidance: `.ignoresSafeArea(.keyboard)` used incorrectly can hide text fields

## Dynamic Type

- All user-visible text must scale with system font size preference
- **Forbidden**: `Font.system(size: 14)` hardcoded — use `.body`, `.caption`, `.headline`, or `relativeTo:` scaling
- **Allowed exception**: icon/symbol sizes, game HUD elements where fixed layout is required
- Test matrix: default, large, accessibility extra-large
- Long label truncation: use `.lineLimit(nil)` or `.minimumScaleFactor` rather than clipping

## Dark Mode

- **Never hardcode hex colors** for UI elements — use semantic system colors or `Color(.label)`, `Color(.systemBackground)`, etc.
- Custom brand colors: define in `.xcassets` with both Light and Dark variants (or use `UIColor(dynamicProvider:)`)
- `Color(hex: "#...")` for decorative/game elements is acceptable; for text/background on content views it's a violation
- Preview both modes: `Group { ContentView().colorScheme(.light); ContentView().colorScheme(.dark) }`

## VoiceOver & Accessibility

- Every interactive custom view needs `.accessibilityLabel()`
- Image-only buttons must have `.accessibilityLabel("Delete photo")`; don't rely on the image name
- Decorative images: `.accessibilityHidden(true)`
- Progress indicators: `.accessibilityValue("\(Int(progress * 100))%")`
- List rows with multiple interactive children: use `.accessibilityElement(children: .combine)` or provide explicit roles
- Custom gesture actions: provide `.accessibilityAction` alternatives

## Navigation Patterns

- **Don't break swipe-back**: never intercept `UINavigationController` back gesture unless providing a custom alternative
- **Tab bar visibility**: never hide the tab bar during push navigation (violates HIG — use `.toolbar(.hidden, for: .tabBar)` only with extreme care)
- **Hamburger menus**: use `TabView` (up to 5 tabs) or `List`-based navigation in a sidebar; hamburger menus are not native iOS pattern
- **Back button label**: should be the title of the previous screen, not "Back"
- `.navigationBarBackButtonHidden(true)` without a custom back button is a trap — user loses back navigation

## Modals & Sheets

- Every presented sheet/modal must have a dismissal path: an explicit close button or swipe-to-dismiss enabled
- `.interactiveDismissDisabled(true)` must only be used when the user must complete or cancel a form; always provide an explicit Cancel button
- `.presentationDetents`: if using `.medium`, ensure content fits and is scrollable if it might overflow

## Typography & Fonts

- Use SF Pro (system font) by default — custom fonts require Dynamic Type support
- Custom font with `Font.custom("...", size: N)` → should use `Font.custom("...", size: N, relativeTo: .body)` to scale
- Avoid all-caps labels (use `.textCase(.uppercase)` modifier so VoiceOver reads naturally)

## Severity Classification

| Finding | Severity |
|---|---|
| Touch target <44pt on primary action | 🟠 High |
| Content hidden under safe area in production | 🟠 High |
| No Dynamic Type support (all fixed sizes) | 🟠 High |
| Dark Mode hardcoded colors on content views | 🟡 Medium |
| Missing VoiceOver labels on interactive views | 🟡 Medium |
| Tab bar hidden during navigation | 🟡 Medium |
| Non-dismissable modal without Cancel button | 🟠 High |
| Hamburger menu instead of tab bar | 🟢 Low |
| Custom font without Dynamic Type scaling | 🟢 Low |
