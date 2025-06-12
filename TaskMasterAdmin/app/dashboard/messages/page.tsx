"use client"

import { useEffect, useState } from "react"
import { ref, get, remove } from "firebase/database"
import { database } from "@/lib/firebase"
import type { Message } from "@/lib/types"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { useToast } from "@/components/ui/use-toast"
import { MoreHorizontal, Search, MessageSquare, Trash2, Mail } from "lucide-react"
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"

export default function MessagesPage() {
  const [messages, setMessages] = useState<Record<string, Message>>({})
  const [filteredMessages, setFilteredMessages] = useState<Record<string, Message>>({})
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState("")
  const [deleteMessageId, setDeleteMessageId] = useState<string | null>(null)
  const [viewMessageId, setViewMessageId] = useState<string | null>(null)
  const { toast } = useToast()

  useEffect(() => {
    const fetchMessages = async () => {
      try {
        const messagesRef = ref(database, "messages")
        const snapshot = await get(messagesRef)
        if (snapshot.exists()) {
          const messagesData = snapshot.val()
          setMessages(messagesData)
          setFilteredMessages(messagesData)
        }
      } catch (error) {
        console.error("Error fetching messages:", error)
        toast({
          title: "Error",
          description: "Failed to load messages",
          variant: "destructive",
        })
      } finally {
        setLoading(false)
      }
    }

    fetchMessages()
  }, [toast])

  useEffect(() => {
    if (searchQuery.trim() === "") {
      setFilteredMessages(messages)
    } else {
      const filtered = Object.entries(messages).reduce(
        (acc, [id, message]) => {
          const matchesSearch =
            message.email?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            message.message?.toLowerCase().includes(searchQuery.toLowerCase())

          if (matchesSearch) {
            acc[id] = message
          }
          return acc
        },
        {} as Record<string, Message>,
      )

      setFilteredMessages(filtered)
    }
  }, [searchQuery, messages])

  const handleDeleteMessage = async () => {
    if (!deleteMessageId) return

    try {
      const messageRef = ref(database, `messages/${deleteMessageId}`)
      await remove(messageRef)

      setMessages((prev) => {
        const updated = { ...prev }
        delete updated[deleteMessageId]
        return updated
      })

      toast({
        title: "Success",
        description: "Message deleted successfully",
      })
    } catch (error) {
      console.error("Error deleting message:", error)
      toast({
        title: "Error",
        description: "Failed to delete message",
        variant: "destructive",
      })
    } finally {
      setDeleteMessageId(null)
    }
  }

  const formatDate = (timestamp: number) => {
    return new Date(timestamp).toLocaleString()
  }

  return (
    <div className="animate-fade-in space-y-6">
      <div className="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <h1 className="text-3xl font-bold">Messages</h1>
          <p className="text-muted-foreground">View and manage customer messages</p>
        </div>
        <div className="relative w-full md:w-64">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search messages..."
            className="pl-8"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <MessageSquare className="mr-2 h-5 w-5" />
            Message Management
          </CardTitle>
          <CardDescription>You have {Object.keys(filteredMessages).length} messages in total</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>ID</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Message Preview</TableHead>
                <TableHead>Date</TableHead>
                <TableHead className="w-[100px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center">
                    Loading messages...
                  </TableCell>
                </TableRow>
              ) : Object.keys(filteredMessages).length === 0 ? (
                <TableRow>
                  <TableCell colSpan={5} className="text-center">
                    No messages found
                  </TableCell>
                </TableRow>
              ) : (
                Object.entries(filteredMessages).map(([id, message]) => (
                  <TableRow key={id}>
                    <TableCell className="font-mono text-xs">{id.substring(0, 10)}...</TableCell>
                    <TableCell>
                      <div className="flex items-center">
                        <Mail className="mr-2 h-4 w-4 text-muted-foreground" />
                        {message.email}
                      </div>
                    </TableCell>
                    <TableCell>
                      {message.message.length > 50 ? `${message.message.substring(0, 50)}...` : message.message}
                    </TableCell>
                    <TableCell>{formatDate(message.timestamp)}</TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon">
                            <MoreHorizontal className="h-4 w-4" />
                            <span className="sr-only">Open menu</span>
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem onClick={() => setViewMessageId(id)}>
                            <MessageSquare className="mr-2 h-4 w-4" />
                            View Message
                          </DropdownMenuItem>
                          <DropdownMenuItem className="text-destructive" onClick={() => setDeleteMessageId(id)}>
                            <Trash2 className="mr-2 h-4 w-4" />
                            Delete
                          </DropdownMenuItem>
                        </DropdownMenuContent>
                      </DropdownMenu>
                    </TableCell>
                  </TableRow>
                ))
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <AlertDialog open={!!deleteMessageId} onOpenChange={() => setDeleteMessageId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the message.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={handleDeleteMessage} className="bg-destructive">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>

      <Dialog open={!!viewMessageId} onOpenChange={() => setViewMessageId(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Message Details</DialogTitle>
            <DialogDescription>{viewMessageId && messages[viewMessageId]?.email}</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="rounded-md bg-muted p-4">
              <p className="whitespace-pre-wrap">{viewMessageId && messages[viewMessageId]?.message}</p>
            </div>
            <p className="text-sm text-muted-foreground">
              Received on: {viewMessageId && formatDate(messages[viewMessageId]?.timestamp)}
            </p>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
