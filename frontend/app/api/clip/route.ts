import { NextRequest, NextResponse } from "next/server";
import { auth } from "@/lib/auth";
import db from "@/lib/db";
import { payment } from "@/lib/schema";
import { eq } from "drizzle-orm";

const LOCAL_DEV_BYPASS = !process.env.DATABASE_URL;

export async function POST(req: NextRequest) {
  let userId = "local-user";

  if (!LOCAL_DEV_BYPASS) {
    // Authenticate & ensure the user is premium
    const session = await auth.api.getSession({ headers: new Headers(req.headers) });
    if (!session || !session.user) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const latestPayment = await db
      .select()
      .from(payment)
      .where(eq(payment.userId, session.user.id))
      .orderBy(payment.createdAt)
      .limit(1);

    if (latestPayment.length === 0 || latestPayment[0].status !== "active") {
      return NextResponse.json({ error: "Forbidden: Premium subscription required" }, { status: 403 });
    }

    userId = session.user.id;
  }

  const body = await req.json();

  const backendPayload = {
    ...body,
    url: body.url,
    userId,
  };

  if (!backendPayload.url) {
    return NextResponse.json({ error: "url field is required" }, { status: 400 });
  }

  const backendUrl = process.env.BACKEND_API_URL || "http://localhost:3001";
  const backendRes = await fetch(`${backendUrl}/api/clip`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(backendPayload),
  });

  const json = await backendRes.json();
  return NextResponse.json(json, { status: backendRes.status });
}
