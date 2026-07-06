# Pet profile sharing widgets

Role-specific sharing UI extracted from `sharing_section.dart`.

| Widget | File | When shown |
|--------|------|------------|
| `SharingSection` | `screens/widgets/sharing_section.dart` | Orchestrator (owner / foster / follower) |
| `FollowerSharingContent` | `follower_sharing_content.dart` | Shared pet follower |
| `FosterSharingContent` | `foster_sharing_content.dart` | Foster parent view |
| `OwnerSharingContent` | `owner_sharing_content.dart` | Pet owner |
| `ShareLinkTile` | `share_link_tile.dart` | Single share link row |
| `AccessTile` | `access_tile.dart` | Guardian access row |

Tests: `test/features/pet_profile/presentation/widgets/sharing/`
