export interface User {
  email: string
  userType: string
  name?: string
  profileImage?: string
  profileImageUrl?: string
  authToken?: string
}

export interface Service {
  serviceId: string
  serviceName: string
  description: string
  price: string
  duration: string
  serviceType: string
  imageUrl: string
  email: string
  whatsapp: string
  companyId: string
  createdAt: number
  accessToken: string
  reviews?: Record<string, Review>
}

export interface Review {
  rating: number
  review: string
  status: string
  user: string
}

export interface Company {
  services: Record<string, Service>
}

export interface Booking {
  bookingTime: number
  companyId: string
  serviceId: string
  serviceName: string
  userId: string
  userName: string
  status?: string
  invoiceUrl?: string
  paymentId?: string
}

export interface Message {
  email: string
  message: string
  timestamp: number
}

export interface Account {
  email: string
  password: string
}

export interface Banner {
  id: string
  imageUrl: string
  title: string
  description?: string
  link?: string
  active: boolean
  createdAt: number
}

export interface Stats {
  totalUsers: number
  totalCompanies: number
  totalServices: number
  totalBookings: number
  pendingBookings: number
  completedBookings: number
  totalMessages: number
}
