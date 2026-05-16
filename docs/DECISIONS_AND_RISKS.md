# Decisions And Risks

Last updated: 2026-05-20.

## Decisions Already Taken

### Role-first signup

Create Account now starts at role selection before auth credential collection.
This matches the client requirement that profile details depend on selected role.

### Email is read-only in profile forms

Email comes from Firebase Auth or Google sign-in and is displayed as a contact
field. Users do not need to re-enter it in profile completion.

### Username uniqueness is app-level

The app checks `usernameLower` in Firestore before saving profile data.
This is not a database uniqueness constraint. It is acceptable for the current
MVP but can race if two users submit the same username simultaneously.

### Role details are stored as a flexible map

`roleDetails` is a `Map<String, dynamic>` instead of strongly typed per-role
models. This keeps notification targeting and admin filtering flexible while the
client requirements evolve.

### Communities are Firestore-driven

Communities are not permanently hardcoded. Four default communities are seeded
only when Firestore is empty. Production/community admin tooling should own
creation and naming.

### Community comments live under announcements

The chosen shape is:

`communities/{communityId}/announcements/{postId}/comments/{commentId}`

This keeps comments scoped to the announcement and allows collection group
queries for My Activity.

### Comments are shown in a bottom sheet

Community announcement comments were moved out of the main feed to reduce
screen clutter and match the requested UX.

### Mentions are data-driven

For targeted activity/notification behavior, admin replies should include target
uids in `mentionedUserIds`. Text-only mentions are not a dependable data model.

### Admin-only content creation

The mobile app is primarily for consumption and interaction. Admin creation of
articles, posts, community announcements, moderation, and notifications is
expected from a separate admin repo/tool.

## Known Risks

### Firestore rules need cleanup

The rules file has at least two areas that need review:

- Accidental nested comments rule under article comments.
- `sharesCount` in rules versus `shareCount` in code.

### Admin UID is hardcoded

`firestore.rules` checks a single UID. This is fragile for team/admin growth.
Use custom claims or an `admins/{uid}` lookup when the admin model stabilizes.

### Analyze is not clean

`flutter analyze` currently exits nonzero because of existing warnings/infos.
Known categories include deprecated `withOpacity`, unused imports, unnecessary
nullability/underscore warnings, and Google Sign-In v7 API cleanup.

### Encoding artifacts exist

Several source files contain mojibake in comments and display strings from
earlier edits. Avoid copying those into new code. A dedicated cleanup pass is
recommended.

### No automated coverage around new flows

The role-based onboarding and community activity/comment flows are currently
verified manually. Add widget/provider tests before large follow-up refactors.

### Username uniqueness can race

Two users can theoretically pass the uniqueness query at the same time. A future
server-side reservation document such as `usernames/{usernameLower}` would be
safer.

### Activity depends on Firestore indexes/rules

My Activity uses collection group queries. If activity appears empty in
production, check:

- deployed Firestore rules
- missing Firestore composite/index prompts
- whether admin replies set `mentionedUserIds`
- whether the user is authenticated

### Community unread behavior is timestamp-based

Unread badges compare announcement timestamps against
`lastReadAnnouncementAt`. This intentionally ignores member join/system chatter
where the UI filters it as non-announcement activity.

## Update Protocol

When changing the app:

1. Update the code.
2. Update the relevant doc in this directory.
3. If Firestore shapes or rules changed, update `DATA_CONTRACTS.md`.
4. If a product decision changed, update this file.
5. If a future chat needs a new briefing, update `HANDOFF.md`.
6. Run the narrowest useful verification command and record any known failure.

## Loading UX Note

Submitting profile/auth forms should use one visible progress indicator for the
same action. The profile completion, edit profile, and change password forms
show progress in their action button instead of also stacking a page spinner.
