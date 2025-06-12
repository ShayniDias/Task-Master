"use client"

import { useEffect, useState } from "react"
import { ref, get } from "firebase/database"
import { database } from "@/lib/firebase"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Skeleton } from "@/components/ui/skeleton"
import type { Stats } from "@/lib/types"
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts"
import { Users, Building2, Calendar, MessageSquare, Clock, CheckCircle } from "lucide-react"

export default function Dashboard() {
  const [stats, setStats] = useState<Stats | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    const fetchData = async () => {
      try {
        const usersRef = ref(database, "users")
        const companiesRef = ref(database, "companies")
        const bookingsRef = ref(database, "bookings")
        const messagesRef = ref(database, "messages")

        const [usersSnapshot, companiesSnapshot, bookingsSnapshot, messagesSnapshot] = await Promise.all([
          get(usersRef),
          get(companiesRef),
          get(bookingsRef),
          get(messagesRef),
        ])

        const users = usersSnapshot.val() || {}
        const companies = companiesSnapshot.val() || {}
        const bookings = bookingsSnapshot.val() || {}
        const messages = messagesSnapshot.val() || {}

        // Count services across all companies
        let totalServices = 0
        Object.values(companies).forEach((company: any) => {
          if (company.services) {
            totalServices += Object.keys(company.services).length
          }
        })

        // Count pending and completed bookings
        let pendingBookings = 0
        let completedBookings = 0
        Object.values(bookings).forEach((booking: any) => {
          if (booking.status === "pending") {
            pendingBookings++
          } else if (booking.status === "completed") {
            completedBookings++
          }
        })

        setStats({
          totalUsers: Object.keys(users).length,
          totalCompanies: Object.keys(companies).length,
          totalServices,
          totalBookings: Object.keys(bookings).length,
          pendingBookings,
          completedBookings,
          totalMessages: Object.keys(messages).length,
        })
      } catch (error) {
        console.error("Error fetching data:", error)
      } finally {
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  const barChartData = stats
    ? [
        { name: "Users", value: stats.totalUsers },
        { name: "Companies", value: stats.totalCompanies },
        { name: "Services", value: stats.totalServices },
        { name: "Bookings", value: stats.totalBookings },
      ]
    : []

  const pieChartData = stats
    ? [
        { name: "Pending", value: stats.pendingBookings },
        { name: "Completed", value: stats.completedBookings },
        {
          name: "Other",
          value: stats.totalBookings - stats.pendingBookings - stats.completedBookings,
        },
      ]
    : []

  const COLORS = ["#0088FE", "#00C49F", "#FFBB28"]

  const statCards = [
    {
      title: "Total Users",
      value: stats?.totalUsers || 0,
      icon: Users,
      color: "text-blue-500",
      bgColor: "bg-blue-100 dark:bg-blue-600/20",
    },
    {
      title: "Total Companies",
      value: stats?.totalCompanies || 0,
      icon: Building2,
      color: "text-purple-500",
      bgColor: "bg-purple-100 dark:bg-purple-900/20",
    },
    {
      title: "Total Bookings",
      value: stats?.totalBookings || 0,
      icon: Calendar,
      color: "text-green-500",
      bgColor: "bg-green-100 dark:bg-green-900/20",
    },
    {
      title: "Total Messages",
      value: stats?.totalMessages || 0,
      icon: MessageSquare,
      color: "text-yellow-500",
      bgColor: "bg-yellow-100 dark:bg-yellow-900/20",
    },
    {
      title: "Pending Bookings",
      value: stats?.pendingBookings || 0,
      icon: Clock,
      color: "text-orange-500",
      bgColor: "bg-orange-100 dark:bg-orange-900/20",
    },
    {
      title: "Completed Bookings",
      value: stats?.completedBookings || 0,
      icon: CheckCircle,
      color: "text-teal-500",
      bgColor: "bg-teal-100 dark:bg-teal-900/20",
    },
  ]

  return (
    <div className="animate-fade-in space-y-6">
      <div>
        <h1 className="text-3xl font-bold">Dashboard</h1>
        <p className="text-muted-foreground">Welcome to TaskMaster admin dashboard</p>
      </div>

      <div className="grid-stats">
        {statCards.map((card, index) => (
          <Card key={index} className="animate-slide-in" style={{ animationDelay: `${index * 0.1}s` }}>
            <CardContent className="flex items-center p-6">
              <div className={`mr-4 rounded-full p-2 ${card.bgColor}`}>
                <card.icon className={`h-6 w-6 ${card.color}`} />
              </div>
              <div>
                <p className="text-sm font-medium text-muted-foreground">{card.title}</p>
                {loading ? <Skeleton className="h-8 w-16" /> : <p className="text-2xl font-bold">{card.value}</p>}
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      <Tabs defaultValue="overview" className="w-full">
        <TabsList>
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="bookings">Bookings</TabsTrigger>
        </TabsList>
        <TabsContent value="overview" className="space-y-4">
          <Card className="animate-fade-in">
            <CardHeader>
              <CardTitle>Statistics Overview</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <Skeleton className="h-[300px] w-full" />
              ) : (
                <ResponsiveContainer width="100%" height={300}>
                  <BarChart data={barChartData}>
                    <CartesianGrid strokeDasharray="3 3" />
                    <XAxis dataKey="name" />
                    <YAxis />
                    <Tooltip />
                    <Bar dataKey="value" fill="#3b82f6" />
                  </BarChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        </TabsContent>
        <TabsContent value="bookings" className="space-y-4">
          <Card className="animate-fade-in">
            <CardHeader>
              <CardTitle>Booking Status</CardTitle>
            </CardHeader>
            <CardContent>
              {loading ? (
                <Skeleton className="h-[300px] w-full" />
              ) : (
                <ResponsiveContainer width="100%" height={300}>
                  <PieChart>
                    <Pie
                      data={pieChartData}
                      cx="50%"
                      cy="50%"
                      labelLine={false}
                      outerRadius={100}
                      fill="#8884d8"
                      dataKey="value"
                      label={({ name, percent }) => `${name}: ${(percent * 100).toFixed(0)}%`}
                    >
                      {pieChartData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip />
                  </PieChart>
                </ResponsiveContainer>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  )
}
