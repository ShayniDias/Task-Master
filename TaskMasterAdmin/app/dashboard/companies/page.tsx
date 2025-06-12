"use client"

import { useEffect, useState } from "react"
import { ref, get } from "firebase/database"
import { database } from "@/lib/firebase"
import type { Company, Service } from "@/lib/types"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Accordion, AccordionContent, AccordionItem, AccordionTrigger } from "@/components/ui/accordion"
import { Input } from "@/components/ui/input"
import { useToast } from "@/components/ui/use-toast"
import { Search, Building2, Clock, DollarSign, Star } from "lucide-react"
import { Badge } from "@/components/ui/badge"

export default function CompaniesPage() {
  const [companies, setCompanies] = useState<Record<string, Company>>({})
  const [filteredCompanies, setFilteredCompanies] = useState<Record<string, Company>>({})
  const [loading, setLoading] = useState(true)
  const [searchQuery, setSearchQuery] = useState("")
  const { toast } = useToast()

  useEffect(() => {
    const fetchCompanies = async () => {
      try {
        const companiesRef = ref(database, "companies")
        const snapshot = await get(companiesRef)
        if (snapshot.exists()) {
          setCompanies(snapshot.val())
          setFilteredCompanies(snapshot.val())
        }
      } catch (error) {
        console.error("Error fetching companies:", error)
        toast({
          title: "Error",
          description: "Failed to load companies",
          variant: "destructive",
        })
      } finally {
        setLoading(false)
      }
    }

    fetchCompanies()
  }, [toast])

  useEffect(() => {
    if (searchQuery.trim() === "") {
      setFilteredCompanies(companies)
    } else {
      const filtered = Object.entries(companies).reduce(
        (acc, [id, company]) => {
          // Check if any service matches the search query
          const hasMatchingService = Object.values(company.services || {}).some(
            (service) =>
              service.serviceName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
              service.description?.toLowerCase().includes(searchQuery.toLowerCase()) ||
              service.serviceType?.toLowerCase().includes(searchQuery.toLowerCase()),
          )

          if (id.toLowerCase().includes(searchQuery.toLowerCase()) || hasMatchingService) {
            acc[id] = company
          }
          return acc
        },
        {} as Record<string, Company>,
      )

      setFilteredCompanies(filtered)
    }
  }, [searchQuery, companies])

  const calculateAverageRating = (service: Service) => {
    if (!service.reviews) return "No ratings"

    const reviews = Object.values(service.reviews)
    if (reviews.length === 0) return "No ratings"

    const sum = reviews.reduce((acc, review) => acc + review.rating, 0)
    return (sum / reviews.length).toFixed(1)
  }

  return (
    <div className="animate-fade-in space-y-6">
      <div className="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <h1 className="text-3xl font-bold">Companies</h1>
          <p className="text-muted-foreground">View all service providers</p>
        </div>
        <div className="relative w-full md:w-64">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Search companies or services..."
            className="pl-8"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
        </div>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-10">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent"></div>
        </div>
      ) : Object.keys(filteredCompanies).length === 0 ? (
        <Card className="flex flex-col items-center justify-center p-10 text-center">
          <Building2 className="mb-4 h-16 w-16 text-muted-foreground" />
          <h3 className="text-lg font-semibold">No companies found</h3>
          <p className="text-muted-foreground">Try adjusting your search query</p>
        </Card>
      ) : (
        <div className="space-y-6">
          {Object.entries(filteredCompanies).map(([companyId, company]) => (
            <Card key={companyId} className="overflow-hidden">
              <CardHeader>
                <CardTitle className="flex items-center">
                  <Building2 className="mr-2 h-5 w-5" />
                  Company ID: {companyId}
                </CardTitle>
                <CardDescription>{Object.keys(company.services || {}).length} services offered</CardDescription>
              </CardHeader>
              <CardContent>
                <Accordion type="single" collapsible className="w-full">
                  <AccordionItem value="services">
                    <AccordionTrigger>Services</AccordionTrigger>
                    <AccordionContent>
                      <div className="grid gap-4 md:grid-cols-2">
                        {Object.entries(company.services || {}).map(([serviceId, service]) => (
                          <Card key={serviceId} className="overflow-hidden">
                            <div className="aspect-video w-full overflow-hidden">
                              <img
                                src={service.imageUrl || "/placeholder.svg?height=200&width=400"}
                                alt={service.serviceName}
                                className="h-full w-full object-cover"
                              />
                            </div>
                            <CardContent className="p-4">
                              <div className="mb-2 flex items-center justify-between">
                                <h3 className="text-lg font-semibold">{service.serviceName}</h3>
                                <Badge>{service.serviceType}</Badge>
                              </div>
                              <p className="mb-2 text-sm text-muted-foreground">{service.description}</p>
                              <div className="mt-4 flex flex-wrap gap-2">
                                <div className="flex items-center text-sm">
                                  <DollarSign className="mr-1 h-4 w-4" />${service.price}
                                </div>
                                <div className="flex items-center text-sm">
                                  <Clock className="mr-1 h-4 w-4" />
                                  {service.duration} hr
                                </div>
                                <div className="flex items-center text-sm">
                                  <Star className="mr-1 h-4 w-4 text-yellow-500" />
                                  {calculateAverageRating(service)}
                                </div>
                              </div>
                              {service.email && (
                                <div className="mt-2 text-xs text-muted-foreground">Contact: {service.email}</div>
                              )}
                            </CardContent>
                          </Card>
                        ))}
                      </div>
                    </AccordionContent>
                  </AccordionItem>
                </Accordion>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
