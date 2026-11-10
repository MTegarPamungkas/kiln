export default function Logo({ size = 30 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" aria-hidden="true">
      <defs>
        <linearGradient id="kiln-logo" x1="8" y1="8" x2="56" y2="56" gradientUnits="userSpaceOnUse">
          <stop stopColor="#38bdf8" />
          <stop offset=".55" stopColor="#2dd4bf" />
          <stop offset="1" stopColor="#a78bfa" />
        </linearGradient>
      </defs>
      <rect width="64" height="64" rx="16" fill="currentColor" opacity=".08" />
      <path
        d="M32 8c8.5 7.5 13.5 15 13.5 23a13.5 13.5 0 1 1-27 0c0-5.2 2.1-9.4 6.3-13.5 0 5.2 2 8.3 5.2 9.4-1.1-6.2-.2-12.5 2-18.9Z"
        fill="url(#kiln-logo)"
      />
      <path
        d="M32 33c3.1 3.1 5.2 6.2 5.2 9.3a5.2 5.2 0 0 1-10.4 0c0-2.1 1-4.2 3.1-6.2 0 2.1 1 3.1 2.1 3.1-1-2.1-1-4.2 0-6.2Z"
        fill="#0b1220"
        opacity=".55"
      />
    </svg>
  );
}
