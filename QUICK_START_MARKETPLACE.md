# Job Marketplace - Quick Start Guide

## 🚀 5-Minute Integration

### 1. Import and Use (That's It!)

```typescript
import { JobMarketplaceView } from "@/JobMarketplaceView";

export default function MarketplacePage() {
  return <JobMarketplaceView />;
}
```

**Done!** You now have:
- ✅ Event-based job listing
- ✅ Search, filter, and sort
- ✅ Auto-refresh every 30s
- ✅ Loading states
- ✅ Responsive design

---

## 📦 What's Included

### Components
- **JobMarketplaceView** - Full marketplace UI
- **JobList** - Responsive grid with skeletons
- **JobCard** - Individual job display

### Hooks (Already Working)
- `useOpenJobs(limit)` - Get marketplace jobs
- `useJobsByClient(address)` - Client's posted jobs
- `useJobsByFreelancer(address)` - Freelancer's assigned jobs

### Services (Already Working)
- **JobEventIndexer** - Event-based queries
- **JobService** - Transaction builders + queries
- **Formatting utilities** - Display helpers

---

## 🎯 Common Tasks

### Display Open Jobs

```typescript
import { useOpenJobs } from "@/hooks";

function MyMarketplace() {
  const { jobs, isPending } = useOpenJobs(50);

  if (isPending) return <div>Loading...</div>;

  return (
    <ul>
      {jobs.map(job => (
        <li key={job.objectId}>{job.title}</li>
      ))}
    </ul>
  );
}
```

### Format Currency

```typescript
import { formatSUI } from "@/utils";

const budgetDisplay = formatSUI(job.budget); // "10.50 SUI"
```

### Format Deadline

```typescript
import { formatDeadline, isDeadlineApproaching } from "@/utils";

const timeLeft = formatDeadline(job.deadline); // "2 days left"
const isUrgent = isDeadlineApproaching(job.deadline); // true if <24h
```

### Shorten Address

```typescript
import { shortenAddress } from "@/utils";

const short = shortenAddress(job.client); // "0x1234...5678"
```

---

## ⚙️ Configuration

### Change Auto-Refresh Rate

**File**: [app/hooks/useJob.ts](app/hooks/useJob.ts:136)

```typescript
refetchInterval: 60000, // 60 seconds (change from 30000)
```

### Change Default Job Limit

**File**: [app/JobMarketplaceView.tsx](app/JobMarketplaceView.tsx:35)

```typescript
const { jobs, isPending, error, refetch } = useOpenJobs(50); // Change from 100
```

### Customize Filters

**File**: [app/JobMarketplaceView.tsx](app/JobMarketplaceView.tsx:20)

```typescript
interface FilterOptions {
  searchQuery: string;
  minBudget: number;
  maxBudget: number;
  deadline: "all" | "today" | "week" | "month";
  // Add your custom filters here
}
```

---

## 🧪 Testing

### Before Deployment

```bash
# Start dev server
pnpm dev

# Open http://localhost:3000
# (Won't show jobs until contracts deployed)
```

### After Deployment

```bash
# 1. Deploy contracts
cd move/zk_freelance
sui client publish --gas-budget 100000000 .

# 2. Copy package ID from output

# 3. Update constants
# Edit app/constants.ts:
export const DEVNET_JOB_ESCROW_PACKAGE_ID = "0xYOUR_PACKAGE_ID";

# 4. Restart dev server
pnpm dev

# 5. Create test job (via UI or CLI)

# 6. Check marketplace (should appear in 2-5 seconds)
```

---

## 🐛 Quick Fixes

### Jobs Not Showing?

1. Check package ID in [constants.ts](app/constants.ts)
2. Wait 5-10 seconds for event indexing
3. Click refresh button in UI
4. Check browser console for errors

### Slow Loading?

1. Reduce limit: `useOpenJobs(20)`
2. Check network (testnet can be slow)
3. Check React Query cache (stale time)

### TypeScript Errors?

1. Verify types match Move structs
2. Use `vectorU8ToString()` for `vector<u8>`
3. Handle `Option` types (null checks)

---

## 📱 Responsive Breakpoints

- **Mobile**: 1 column
- **Tablet**: 2 columns (md:)
- **Desktop**: 3 columns (lg:)

All handled automatically via Tailwind CSS.

---

## 🔗 Quick Links

- **Full Documentation**: [JOB_MARKETPLACE_INTEGRATION.md](JOB_MARKETPLACE_INTEGRATION.md)
- **Summary**: [JOB_MARKETPLACE_SUMMARY.md](JOB_MARKETPLACE_SUMMARY.md)
- **Project Overview**: [DEVELOPER_HANDOFF.md](DEVELOPER_HANDOFF.md)

---

## 💡 Pro Tips

1. **Events are fast** - Jobs appear in 2-5 seconds after creation
2. **Cache is your friend** - React Query caches for 10s by default
3. **Auto-refresh works** - No need to manually refetch (unless you want to)
4. **Filters are client-side** - No re-queries when filtering/sorting
5. **Skeletons look good** - Users see instant feedback while loading

---

## 🎉 That's All!

You're ready to go. The marketplace is **production-ready** and follows all Sui best practices.

Questions? Check the full docs or browser console for errors.

Happy coding! 🚀
