import {
  Activity,
  Bell,
  Blocks,
  Bug,
  CalendarDays,
  Code2,
  Compass,
  Database,
  Globe2,
  HardDrive,
  Image,
  KeyRound,
  Languages,
  Layers,
  Link2,
  MapPin,
  Palette,
  ScrollText,
  Settings2,
  Share2,
  Shield,
  Tag,
  Users,
  Wifi,
  Wrench,
  Boxes,
} from 'lucide-react';
import { CATEGORY_META } from '../lib/categories';

const ICONS = {
  Activity,
  Bell,
  Blocks,
  Bug,
  CalendarDays,
  Code2,
  Compass,
  Database,
  Globe2,
  HardDrive,
  Image,
  KeyRound,
  Languages,
  Layers,
  Link2,
  MapPin,
  Palette,
  ScrollText,
  Settings2,
  Share2,
  Shield,
  Tag,
  Users,
  Wifi,
  Wrench,
};

export default function ExtensionIcon({ category, size = 22 }) {
  const meta = CATEGORY_META[category];
  const Icon = ICONS[meta?.icon] ?? Boxes;
  return (
    <span className={`ext-icon accent-${meta?.group ?? 'tooling'}`} aria-hidden="true">
      <Icon size={size} strokeWidth={1.8} />
    </span>
  );
}
