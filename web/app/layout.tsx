import { Analytics } from "@vercel/analytics/next"
import { SpeedInsights } from "@vercel/speed-insights/next"

export const metadata = {
  title: 'Aevoria Simulator',
  description: 'CUR-based governance and space civilization sandbox',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body style={{ margin: 0, padding: 0, background: '#000' }}>
        <Analytics/>
        <SpeedInsights/>
        {children}
      </body>
    </html>
  );
}