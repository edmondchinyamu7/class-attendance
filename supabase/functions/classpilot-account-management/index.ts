import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const reply = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

const normalizeName = (value: unknown) => String(value || "").trim().toLowerCase().replace(/\s+/g, " ");
const DEFAULT_SCHOOL_SUBJECTS = [
  "English", "Maths", "Chichewa", "Bible Knowledge", "Physics", "Chemistry",
  "Social Studies", "Agriculture", "Biology", "Geography", "History"
];
// Wider Malawi secondary-school subject catalogue. These remain optional until a school admin selects them.
const ADDITIONAL_MALAWI_SUBJECTS = [
  "Additional Mathematics", "Business and Financial Studies", "Business Studies", "Computer Studies", "Creative Arts",
  "French", "Kiswahili", "Arabic", "Mandarin (Chinese)", "Sign Language", "Religious and Moral Education",
  "Islamic Education", "Christian Education", "Life Skills", "Home Economics", "Physical Education",
  "Sports Science", "Sports and Recreation", "Media Technology", "Technical Studies", "Technical Drawing (CAD)",
  "Information and Communication Technology (ICT)", "Integrated Science", "Material Science",
  "Carpentry and Joinery", "Welding and Fabrication", "Human Ecology", "Fashion and Fabrics", "Food and Nutrition",
  "Electrical Installation", "Motorcycle Mechanics", "Plumbing", "Travel and Tourism", "Fine Arts", "Performing Arts",
  "Civics", "Social and Life Studies", "Woodwork", "Metalwork", "Clothing and Textiles"
];
const AVAILABLE_SCHOOL_SUBJECTS = [...DEFAULT_SCHOOL_SUBJECTS, ...ADDITIONAL_MALAWI_SUBJECTS];
const normalizePhone = (value: unknown) => {
  const digits = String(value || "").replace(/\D/g, "");
  return digits.startsWith("0") ? "265" + digits.slice(1) : digits;
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return reply({ error: "Method not allowed" }, 405);
  const url = Deno.env.get("SUPABASE_URL") || "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY") || "";
  if (!url || !serviceKey || !anonKey) return reply({ error: "Server configuration is incomplete." }, 500);
  const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
  const authHeader = req.headers.get("Authorization") || "";
  const token = authHeader.startsWith("Bearer ") ? authHeader.slice(7) : "";
  const body = await req.json().catch(() => ({}));
  try {
    if (body.action === "register_school") {
      const schoolName = String(body.schoolName || "").trim();
      const fullName = String(body.fullName || "").trim();
      const email = String(body.email || "").trim().toLowerCase();
      const password = String(body.password || "");
      if (!schoolName || !fullName || !email || password.length < 10) return reply({ error: "Enter all details and use a password of at least 10 characters." }, 400);
      const { data: created, error: createError } = await admin.auth.admin.createUser({ email, password, email_confirm: true, user_metadata: { full_name: fullName } });
      if (createError || !created.user) return reply({ error: createError?.message || "Account creation failed." }, 400);
      const { data: school, error: schoolError } = await admin.from("schools").insert({ name: schoolName, email, admin_user_id: created.user.id }).select("id,name").single();
      if (schoolError) { await admin.auth.admin.deleteUser(created.user.id); return reply({ error: schoolError.message }, 400); }
      const { error: metaError } = await admin.auth.admin.updateUserById(created.user.id, { app_metadata: { role: "school_admin", school_id: school.id } });
      const { error: profileError } = await admin.from("profiles").insert({ id: created.user.id, full_name: fullName, role: "school_admin", school_id: school.id });
      if (metaError || profileError) { await admin.from("schools").delete().eq("id", school.id); await admin.auth.admin.deleteUser(created.user.id); return reply({ error: metaError?.message || profileError?.message || "Could not finish registration." }, 500); }
      const { error: subjectsError } = await admin.from("school_subjects").insert(
        DEFAULT_SCHOOL_SUBJECTS.map((subject_name) => ({ school_id: school.id, subject_name, is_active: true }))
      );
      if (subjectsError) {
        await admin.from("schools").delete().eq("id", school.id);
        await admin.auth.admin.deleteUser(created.user.id);
        return reply({ error: "School registration could not finish setting up the default subjects." }, 500);
      }
      return reply({ ok: true, message: "School registered with the standard subject list. You can now sign in.", school });
    }
    if (body.action === "save_school_subjects") {
      if (!token) return reply({ error: "Sign in as a school administrator first." }, 401);
      const callerClient = createClient(url, anonKey, { global: { headers: { Authorization: "Bearer " + token } }, auth: { autoRefreshToken: false, persistSession: false } });
      const { data: authData, error: authError } = await callerClient.auth.getUser(token);
      const caller = authData.user;
      if (authError || !caller) return reply({ error: "Your session is invalid. Sign in again." }, 401);
      const schoolId = caller.app_metadata?.school_id;
      if (caller.app_metadata?.role !== "school_admin" || !schoolId) return reply({ error: "Only a school administrator can change school subjects." }, 403);

      if (!Array.isArray(body.selectedSubjects) || body.selectedSubjects.length === 0 || body.selectedSubjects.length > 100) {
        return reply({ error: "Select at least one subject. You can manage up to 100 subjects." }, 400);
      }
      const selectedSubjects = [...new Set(body.selectedSubjects.map((value: unknown) => String(value || "").trim()).filter(Boolean))];
      if (!selectedSubjects.length) return reply({ error: "Select at least one subject." }, 400);

      const { data: currentSubjects, error: currentError } = await admin.from("school_subjects")
        .select("id,subject_name").eq("school_id", schoolId);
      if (currentError) return reply({ error: "Could not load your school's subject list." }, 500);
      const allowedNames = new Set([...AVAILABLE_SCHOOL_SUBJECTS, ...(currentSubjects || []).map((item: any) => item.subject_name)]);
      if (selectedSubjects.some((name) => !allowedNames.has(name))) {
        return reply({ error: "One or more selected subjects are not available in your school's subject catalogue." }, 400);
      }

      const { error: upsertError } = await admin.from("school_subjects").upsert(
        selectedSubjects.map((subject_name) => ({ school_id: schoolId, subject_name, is_active: true })),
        { onConflict: "school_id,subject_name" }
      );
      if (upsertError) return reply({ error: "Could not save the selected subjects." }, 500);

      const { data: refreshedSubjects, error: refreshError } = await admin.from("school_subjects")
        .select("id,subject_name").eq("school_id", schoolId);
      if (refreshError) return reply({ error: "Subjects were saved, but the final status could not be confirmed. Refresh and check the list." }, 500);
      const selectedSet = new Set(selectedSubjects);
      const activeIds = (refreshedSubjects || []).filter((item: any) => selectedSet.has(item.subject_name)).map((item: any) => item.id);
      const inactiveIds = (refreshedSubjects || []).filter((item: any) => !selectedSet.has(item.subject_name)).map((item: any) => item.id);
      if (activeIds.length) {
        const { error } = await admin.from("school_subjects").update({ is_active: true }).eq("school_id", schoolId).in("id", activeIds);
        if (error) return reply({ error: "Some subjects could not be activated. Refresh and try again." }, 500);
      }
      if (inactiveIds.length) {
        const { error } = await admin.from("school_subjects").update({ is_active: false }).eq("school_id", schoolId).in("id", inactiveIds);
        if (error) return reply({ error: "Some subjects could not be removed from the active list. Refresh and try again." }, 500);
      }
      return reply({ ok: true, message: "School subjects updated. Removed subjects remain in historical records." });
    }

    if (body.action === "invite_parent") {
      if (!token) return reply({ error: "Sign in as a school administrator first." }, 401);
      const callerClient = createClient(url, anonKey, { global: { headers: { Authorization: "Bearer " + token } }, auth: { autoRefreshToken: false, persistSession: false } });
      const { data: authData, error: authError } = await callerClient.auth.getUser(token);
      const caller = authData.user;
      if (authError || !caller) return reply({ error: "Your session is invalid. Sign in again." }, 401);
      const schoolId = caller.app_metadata?.school_id;
      if (caller.app_metadata?.role !== "school_admin" || !schoolId) return reply({ error: "Only a school administrator can register parents." }, 403);
      const fullName = String(body.fullName || "").trim();
      const phone = String(body.phone || "").trim();
      const email = String(body.email || "").trim().toLowerCase();
      const studentCode = String(body.studentCode || "").trim();
      if (!fullName || !phone || !email || !studentCode) return reply({ error: "Enter the parent name, phone, email and Student ID." }, 400);
      const { data: student, error: studentError } = await admin.from("students").select("id,parent_name,parent_phone,parent_email").eq("school_id", schoolId).eq("student_code", studentCode).maybeSingle();
      if (studentError) return reply({ error: "Could not verify the student enrollment. Try again." }, 500);
      if (!student || !student.parent_name || !student.parent_phone || !student.parent_email) return reply({ error: "Wrong input! Student and parent details don\u0027t match. Please ask the school administrator to complete the student\u0027s parent enrollment details." }, 400);
      const matches = normalizeName(student.parent_name) === normalizeName(fullName) && normalizePhone(student.parent_phone) === normalizePhone(phone) && String(student.parent_email || "").trim().toLowerCase() === email;
      if (!matches) return reply({ error: "Wrong input! Student and parent details don\u0027t match. Please check the information and try again." }, 400);
      let parentUser: any = null;
      let page = 1;
      while (!parentUser && page <= 10) {
        const { data: usersPage, error: usersError } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
        if (usersError) return reply({ error: "Could not verify the parent account." }, 500);
        parentUser = usersPage.users.find((u: any) => (u.email || "").toLowerCase() === email) || null;
        if (usersPage.users.length < 1000) break;
        page++;
      }
      if (parentUser) {
        const { data: profile, error: profileError } = await admin.from("profiles").select("role,school_id,phone,full_name").eq("id", parentUser.id).maybeSingle();
        if (profileError) return reply({ error: "Could not verify the parent profile." }, 500);
        if (!profile || profile.role !== "parent" || profile.school_id !== schoolId || normalizeName(profile.full_name) !== normalizeName(fullName) || normalizePhone(profile.phone) !== normalizePhone(phone)) return reply({ error: "Wrong input! These parent details do not match the existing ClassPilot account. Please contact your school administrator." }, 409);
        const { error: linkError } = await admin.from("parent_student_links").upsert({ parent_user_id: parentUser.id, student_id: student.id });
        if (linkError) return reply({ error: "The child could not be linked to this parent account. Please try again." }, 500);
        return reply({ ok: true, message: "Details verified. This child has been linked to the parent\u0027s existing ClassPilot account." });
      }
      const { data: invited, error: inviteError } = await admin.auth.admin.inviteUserByEmail(email, { data: { full_name: fullName } });
      if (inviteError || !invited.user) return reply({ error: inviteError?.message || "Could not send parent invitation." }, 400);
      const parentId = invited.user.id;
      const { error: metaError } = await admin.auth.admin.updateUserById(parentId, { app_metadata: { role: "parent", school_id: schoolId } });
      const { error: profileError } = await admin.from("profiles").insert({ id: parentId, full_name: fullName, phone, role: "parent", school_id: schoolId });
      const { error: linkError } = await admin.from("parent_student_links").insert({ parent_user_id: parentId, student_id: student.id });
      if (metaError || profileError || linkError) { await admin.auth.admin.deleteUser(parentId); return reply({ error: metaError?.message || profileError?.message || linkError?.message || "Parent registration failed." }, 500); }
      return reply({ ok: true, message: "Details verified. A secure invitation has been sent to the parent to create a password and access the Parent Dashboard." });
    }

    if (body.action === "invite_teacher") {
      if (!token) return reply({ error: "Sign in as a school administrator first." }, 401);
      const callerClient = createClient(url, anonKey, { global: { headers: { Authorization: "Bearer " + token } }, auth: { autoRefreshToken: false, persistSession: false } });
      const { data: authData, error: authError } = await callerClient.auth.getUser(token);
      const caller = authData.user;
      if (authError || !caller) return reply({ error: "Your session is invalid. Sign in again." }, 401);
      const schoolId = caller.app_metadata?.school_id;
      if (caller.app_metadata?.role !== "school_admin" || !schoolId) return reply({ error: "Only a school administrator can invite teachers." }, 403);

      const fullName = String(body.fullName || "").trim();
      const phone = String(body.phone || "").trim();
      const email = String(body.email || "").trim().toLowerCase();
      const className = String(body.className || "").trim();
      const subjectId = String(body.subjectId || "").trim();
      if (!fullName || !phone || !email || !className || !subjectId) return reply({ error: "Enter the teacher name, phone, email, class and subject." }, 400);

      const { data: subject, error: subjectError } = await admin.from("school_subjects")
        .select("id,subject_name").eq("id", subjectId).eq("school_id", schoolId).eq("is_active", true).maybeSingle();
      if (subjectError || !subject) return reply({ error: "Choose a subject currently offered by your school." }, 400);

      let teacherUser: any = null;
      let page = 1;
      while (!teacherUser && page <= 10) {
        const { data: usersPage, error: usersError } = await admin.auth.admin.listUsers({ page, perPage: 1000 });
        if (usersError) return reply({ error: "Could not verify the teacher account." }, 500);
        teacherUser = usersPage.users.find((u: any) => (u.email || "").toLowerCase() === email) || null;
        if (usersPage.users.length < 1000) break;
        page++;
      }

      let createdNewUser = false;
      if (teacherUser) {
        const { data: profile, error: profileError } = await admin.from("profiles")
          .select("role,school_id,phone,full_name").eq("id", teacherUser.id).maybeSingle();
        if (profileError) return reply({ error: "Could not verify the existing teacher profile." }, 500);
        if (!profile || profile.role !== "teacher" || profile.school_id !== schoolId ||
            normalizeName(profile.full_name) !== normalizeName(fullName) ||
            normalizePhone(profile.phone) !== normalizePhone(phone)) {
          return reply({ error: "This email is already registered to a different ClassPilot account or school. Check the teacher details." }, 409);
        }
      } else {
        const { data: invited, error: inviteError } = await admin.auth.admin.inviteUserByEmail(email, { data: { full_name: fullName } });
        if (inviteError || !invited.user) return reply({ error: inviteError?.message || "Could not send the teacher invitation." }, 400);
        teacherUser = invited.user;
        createdNewUser = true;
        const { error: metaError } = await admin.auth.admin.updateUserById(teacherUser.id, {
          app_metadata: { role: "teacher", school_id: schoolId }
        });
        const { error: profileError } = await admin.from("profiles").insert({
          id: teacherUser.id, full_name: fullName, phone, role: "teacher", school_id: schoolId
        });
        if (metaError || profileError) {
          await admin.auth.admin.deleteUser(teacherUser.id);
          return reply({ error: metaError?.message || profileError?.message || "Teacher profile setup failed." }, 500);
        }
      }

      const { error: assignmentError } = await admin.from("teacher_assignments").upsert({
        school_id: schoolId,
        teacher_user_id: teacherUser.id,
        class_name: className,
        school_subject_id: subject.id,
        assigned_by: caller.id
      }, { onConflict: "teacher_user_id,class_name,school_subject_id", ignoreDuplicates: true });
      if (assignmentError) {
        if (createdNewUser) {
          await admin.from("profiles").delete().eq("id", teacherUser.id);
          await admin.auth.admin.deleteUser(teacherUser.id);
        }
        return reply({ error: "Teacher account was not fully assigned: " + assignmentError.message }, 500);
      }
      return reply({
        ok: true,
        message: createdNewUser
          ? "Teacher invitation sent and class/subject assignment saved."
          : "Existing teacher account assigned to this class and subject.",
        teacherId: teacherUser.id,
        className,
        subject: subject.subject_name
      });
    }
    return reply({ error: "Unknown action." }, 400);
  } catch (_err) { return reply({ error: "Unexpected server error. Please try again." }, 500); }
});