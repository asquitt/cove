# /design - iOS/SwiftUI Design Assistant

## Description
Design and implement SwiftUI views for Cove following the established design system.

## Usage
```
/design [component description]
```

## Examples
- `/design task card with completion animation`
- `/design voice capture button`
- `/design meltdown mode overlay`
- `/design daily contract view`

## Instructions

When this command is invoked:

1. **Read the design system** from `.claude/skills/ios-design.md`

2. **Clarify requirements** if the request is vague:
   - What state does this component need to handle?
   - What interactions should it support?
   - Should it support dark mode?

3. **Generate SwiftUI code** that:
   - Uses the Cove color palette (deepOcean, calmSea, etc.)
   - Uses SF Pro Rounded typography
   - Follows the spacing system (xs, sm, md, lg, xl)
   - Includes appropriate animations
   - Adds haptic feedback for interactions
   - Supports accessibility (VoiceOver, dynamic type)

4. **Provide the implementation** with:
   - The main view struct
   - Any supporting views/modifiers
   - Preview provider for testing
   - Usage example

5. **Verify** the code compiles (if Xcode project exists)

## Design Principles for Cove

- **Calm over busy**: Minimal UI, lots of whitespace
- **Soft corners**: Use rounded corners generously
- **Gentle feedback**: Subtle animations, not jarring
- **ADHD-friendly**: Clear hierarchy, one action at a time
- **Meltdown-safe**: Can switch to ultra-minimal mode

## Color Quick Reference

| Name | Hex | Usage |
|------|-----|-------|
| deepOcean | #1a365d | Primary actions |
| calmSea | #2c5282 | Secondary |
| softWave | #4a90a4 | Accents |
| zenGreen | #48bb78 | Success |
| warmSand | #ed8936 | Warning |
| coralAlert | #fc8181 | Danger/Reset |
| cloudWhite | #f7fafc | Background |
| mistGray | #e2e8f0 | Borders |
| deepText | #2d3748 | Text |
