import type { Metadata } from "next";
import "./globals.css";
export const metadata: Metadata = { title: "ClassPilot | Malawi School Management", description: "A modern school management platform for Malawian secondary schools." };
export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) { return <html lang="en"><body>{children}</body></html>; }
