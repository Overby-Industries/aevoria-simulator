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
      <body style={{ margin: 0, padding: 0, overflow: 'hidden', background: '#000' }}>
        {children}
      </body>
    </html>
  );
}