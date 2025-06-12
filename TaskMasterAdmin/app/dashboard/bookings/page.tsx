"use client"

import { useEffect, useState } from "react"
import { ref, get, update } from "firebase/database"
import { database } from "@/lib/firebase"
import type { Booking } from "@/lib/types"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { useToast } from "@/components/ui/use-toast"
import { MoreHorizontal, Search, Calendar, CheckCircle, Clock, FileText, ExternalLink } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

export default function BookingsPage() {
  const [bookings, setBookings] = useState<Record<string, Booking>>({})
  const [filteredBookings, setFilteredBookings] = useState<Record<string, Booking>>({})
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState("")
  const [statusFilter, setStatusFilter] = useState<string>("all")
  const [selectedBooking, setSelectedBooking] = useState<string | null>(null)
  const [selectedStatus, setSelectedStatus] = useState<string>("")
  const { toast } = useToast()

  useEffect(() => {
    const fetchBookings = async () => {
      try {
        const bookingsRef = ref(database, "bookings")
        const snapshot = await get(bookingsRef)
        if (snapshot.exists()) {
          const bookingsData = snapshot.val()
          setBookings(bookingsData)
          setFilteredBookings(bookingsData)
        }
      } catch (error) {
        console.error("Error fetching bookings:", error)
        toast({
          title: "Error",
          description: "Failed to load bookings",
          variant: "destructive",
        })
      } finally {
        setLoading(false)
      }
    }

    fetchBookings()
  }, [toast])

  useEffect(() => {
    let filtered = { ...bookings }

    // Apply status filter
    if (statusFilter !== "all") {
      filtered = Object.entries(filtered).reduce(
        (acc, [id, booking]) => {
          if (
            (statusFilter === "pending" && booking.status === "pending") ||
            (statusFilter === "completed" && booking.status === "completed") ||
            (statusFilter === "none" && !booking.status)
          ) {
            acc[id] = booking
          }
          return acc
        },
        {} as Record<string, Booking>,
      )
    }

    // Apply search filter
    if (searchQuery.trim() !== "") {
      filtered = Object.entries(filtered).reduce(
        (acc, [id, booking]) => {
          const matchesSearch =
            booking.serviceName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            booking.userName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            booking.userId?.toLowerCase().includes(searchQuery.toLowerCase()) ||
            booking.companyId?.toLowerCase().includes(searchQuery.toLowerCase())

          if (matchesSearch) {
            acc[id] = booking
          }
          return acc
        },
        {} as Record<string, Booking>,
      )
    }

    setFilteredBookings(filtered)
  }, [searchQuery, statusFilter, bookings])

  const handleUpdateStatus = async () => {
    if (!selectedBooking || !selectedStatus) return

    try {
      const bookingRef = ref(database, `bookings/${selectedBooking}`)
      await update(bookingRef, { status: selectedStatus })

      setBookings((prev) => ({
        ...prev,
        [selectedBooking]: {
          ...prev[selectedBooking],
          status: selectedStatus,
        },
      }))

      toast({
        title: "Success",
        description: "Booking status updated successfully",
      })
    } catch (error) {
      console.error("Error updating booking status:", error)
      toast({
        title: "Error",
        description: "Failed to update booking status",
        variant: "destructive",
      })
    } finally {
      setSelectedBooking(null)
    }
  }

  const formatDate = (timestamp: number) => {
    return new Date(timestamp).toLocaleString()
  }

  const getStatusBadge = (status?: string) => {
    if (!status) {
      return <Badge variant="outline">None</Badge>
    }
    switch (status) {
      case "pending":
        return (
          <Badge variant="secondary" className="bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300">
            <Clock className="mr-1 h-3 w-3" />
            Pending
          </Badge>
        )
      case "completed":
        return (
          <Badge variant="secondary" className="bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300">
            <CheckCircle className="mr-1 h-3 w-3" />
            Completed
          </Badge>
        )
      default:
        return <Badge variant="outline">{status}</Badge>
    }
  }

  return (
    <div className="animate-fade-in space-y-6">
      <div className="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <h1 className="text-3xl font-bold">Bookings</h1>
          <p className="text-muted-foreground">Manage your bookings</p>
        </div>
        <div className="flex flex-col gap-2 md:flex-row">
          <div className="relative w-full md:w-64">
            <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
            <Input
              placeholder="Search bookings..."
              className="pl-8"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
            />
          </div>
          <Select value={statusFilter} onValueChange={setStatusFilter}>
            <SelectTrigger className="w-full md:w-[180px]">
              <SelectValue placeholder="Filter by status" />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="all">All Statuses</SelectItem>
              <SelectItem value="pending">Pending</SelectItem>
              <SelectItem value="completed">Completed</SelectItem>
              <SelectItem value="none">No Status</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Calendar className="mr-2 h-5 w-5" />
            Booking Management
          </CardTitle>
          <CardDescription>You have {Object.keys(filteredBookings).length} bookings in total</CardDescription>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>ID</TableHead>
                <TableHead>Service</TableHead>
                <TableHead>User</TableHead>
                <TableHead>Date</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="w-[100px]">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {loading ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center">
                    Loading bookings...
                  </TableCell>
                </TableRow>
              ) : Object.keys(filteredBookings).length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} className="text-center">
                    No bookings found
                  </TableCell>
                </TableRow>
              ) : (
                Object.entries(filteredBookings).map(([id, booking]) => (
                  <TableRow key={id}>
                    <TableCell className="font-mono text-xs">{id.substring(0, 10)}...</TableCell>
                    <TableCell>{booking.serviceName}</TableCell>
                    <TableCell>
                      <div>
                        <p>{booking.userName || "Anonymous"}</p>
                        <p className="text-xs text-muted-foreground">{booking.userId.substring(0, 10)}...</p>
                      </div>
                    </TableCell>
                    <TableCell>{formatDate(booking.bookingTime)}</TableCell>
                    <TableCell>{getStatusBadge(booking.status)}</TableCell>
                    <TableCell>
                      <DropdownMenu>
                        <DropdownMenuTrigger asChild>
                          <Button variant="ghost" size="icon">
                            <MoreHorizontal className="h-4 w-4" />
                            <span className="sr-only">Open menu</span>
                          </Button>
                        </DropdownMenuTrigger>
                        <DropdownMenuContent align="end">
                          <DropdownMenuItem
                            onClick={() => {
                              setSelectedBooking(id)
                              setSelectedStatus(booking.status || "")
                            }}
                          >
                            <Clock className="mr-2 h-4 w-4" />
                            Update Status
                          </DropdownMenuItem>
                          {booking.invoiceUrl && (
                            <DropdownMenuItem asChild>
                              <a
                                href={booking.invoiceUrl}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="flex cursor-pointer items-center"
                              >
                                <FileText className="mr-2 h-4 w-4" />
                                View Invoice
                                <ExternalLink className="ml-2 h-3 w-3" />
                              </a>
                            </DropdownMenuItem>
                          )}
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

      <Dialog open={!!selectedBooking} onOpenChange={(open) => !open && setSelectedBooking(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Update Booking Status</DialogTitle>
            <DialogDescription>Change the status of this booking to track its progress.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Select value={selectedStatus} onValueChange={setSelectedStatus}>
                <SelectTrigger>
                  <SelectValue placeholder="Select status" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">Pending</SelectItem>
                  <SelectItem value="completed">Completed</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="flex justify-end space-x-2">
              <Button variant="outline" onClick={() => setSelectedBooking(null)}>
                Cancel
              </Button>
              <Button onClick={handleUpdateStatus}>Save Changes</Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </div>
  )
}
