"use client"

import { useState, useEffect } from "react"
import { ref, get, update } from "firebase/database"
import { updatePassword, EmailAuthProvider, reauthenticateWithCredential } from "firebase/auth"
import { auth, database } from "@/lib/firebase"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { useToast } from "@/components/ui/use-toast"
import { User, Lock, Loader2 } from "lucide-react"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"

export default function AccountPage() {
  const [loading, setLoading] = useState(false)
  const [accounts, setAccounts] = useState<Record<string, { email: string; password: string }>>({})
  const [isPasswordDialogOpen, setIsPasswordDialogOpen] = useState(false)
  const [currentPassword, setCurrentPassword] = useState("")
  const [newPassword, setNewPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const { toast } = useToast()

  useEffect(() => {
    const fetchAccounts = async () => {
      try {
        setLoading(true)
        const accountsRef = ref(database, "accounts")
        const snapshot = await get(accountsRef)
        if (snapshot.exists()) {
          setAccounts(snapshot.val())
        }
      } catch (error) {
        console.error("Error fetching accounts:", error)
        toast({
          title: "Error",
          description: "Failed to load account information",
          variant: "destructive",
        })
      } finally {
        setLoading(false)
      }
    }

    fetchAccounts()
  }, [toast])

  const handlePasswordChange = async () => {
    if (newPassword !== confirmPassword) {
      toast({
        title: "Error",
        description: "New passwords do not match",
        variant: "destructive",
      })
      return
    }

    if (newPassword.length < 6) {
      toast({
        title: "Error",
        description: "Password must be at least 6 characters long",
        variant: "destructive",
      })
      return
    }

    try {
      setLoading(true)
      const user = auth.currentUser
      if (!user || !user.email) {
        throw new Error("User not authenticated")
      }

      // Re-authenticate user
      const credential = EmailAuthProvider.credential(user.email, currentPassword)
      await reauthenticateWithCredential(user, credential)

      // Update password in Firebase Auth
      await updatePassword(user, newPassword)

      // Update password in Realtime Database
      // Find the account that matches the current user's email
      const accountKey = Object.keys(accounts).find((key) => accounts[key].email === user.email)

      if (accountKey) {
        const accountRef = ref(database, `accounts/${accountKey}`)
        await update(accountRef, { password: newPassword })

        // Update local state
        setAccounts((prev) => ({
          ...prev,
          [accountKey]: {
            ...prev[accountKey],
            password: newPassword,
          },
        }))
      }

      toast({
        title: "Success",
        description: "Password updated successfully",
      })

      // Reset form and close dialog
      setCurrentPassword("")
      setNewPassword("")
      setConfirmPassword("")
      setIsPasswordDialogOpen(false)
    } catch (error) {
      console.error("Error updating password:", error)
      toast({
        title: "Error",
        description: "Failed to update password. Please check your current password.",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="animate-fade-in space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Account Settings</h1>
        <p className="text-muted-foreground">Manage your account information</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <User className="mr-2 h-5 w-5" />
              Admin Accounts
            </CardTitle>
            <CardDescription>View admin account information</CardDescription>
          </CardHeader>
          <CardContent>
            {loading ? (
              <div className="flex items-center justify-center py-4">
                <Loader2 className="h-6 w-6 animate-spin text-primary" />
              </div>
            ) : (
              <div className="space-y-4">
                {Object.entries(accounts).map(([key, account]) => (
                  <div key={key} className="rounded-md border p-4">
                    <div className="mb-2 font-semibold">{key}</div>
                    <div className="text-sm text-muted-foreground">Email: {account.email}</div>
                    <div className="text-sm text-muted-foreground">Password: ••••••••</div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center">
              <Lock className="mr-2 h-5 w-5" />
              Security
            </CardTitle>
            <CardDescription>Update your password</CardDescription>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              It's a good idea to use a strong password that you don't use elsewhere.
            </p>
          </CardContent>
          <CardFooter>
            <Button onClick={() => setIsPasswordDialogOpen(true)}>Change Password</Button>
          </CardFooter>
        </Card>
      </div>

      <Dialog open={isPasswordDialogOpen} onOpenChange={setIsPasswordDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Change Password</DialogTitle>
            <DialogDescription>
              Enter your current password and a new password to update your credentials.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="current-password">Current Password</Label>
              <Input
                id="current-password"
                type="password"
                value={currentPassword}
                onChange={(e) => setCurrentPassword(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="new-password">New Password</Label>
              <Input
                id="new-password"
                type="password"
                value={newPassword}
                onChange={(e) => setNewPassword(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="confirm-password">Confirm New Password</Label>
              <Input
                id="confirm-password"
                type="password"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsPasswordDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handlePasswordChange} disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {loading ? "Updating..." : "Update Password"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  )
}
