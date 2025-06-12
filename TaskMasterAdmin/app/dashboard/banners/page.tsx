"use client"

import type React from "react"

import { useEffect, useState, useRef } from "react"
import { ref, get, push, set, remove, update } from "firebase/database"
import { ref as storageRef, uploadBytes, getDownloadURL, deleteObject } from "firebase/storage"
import { database, storage } from "@/lib/firebase"
import type { Banner } from "@/lib/types"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { useToast } from "@/components/ui/use-toast"
import { Plus, Trash2, Edit, Eye, EyeOff, Loader2 } from "lucide-react"
import { Switch } from "@/components/ui/switch"
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog"
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
import { ImageIcon, ExternalLink } from "lucide-react"

export default function BannersPage() {
  const [banners, setBanners] = useState<Record<string, Banner>>({})
  const [loading, setLoading] = useState(true)
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [isDeleteDialogOpen, setIsDeleteDialogOpen] = useState(false)
  const [selectedBanner, setSelectedBanner] = useState<string | null>(null)
  const [formData, setFormData] = useState({
    title: "",
    description: "",
    link: "",
    active: true,
  })
  const [imageFile, setImageFile] = useState<File | null>(null)
  const [imagePreview, setImagePreview] = useState<string | null>(null)
  const [isUploading, setIsUploading] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)
  const { toast } = useToast()

  useEffect(() => {
    const fetchBanners = async () => {
      try {
        const bannersRef = ref(database, "banners")
        const snapshot = await get(bannersRef)
        if (snapshot.exists()) {
          setBanners(snapshot.val())
        }
      } catch (error) {
        console.error("Error fetching banners:", error)
        toast({
          title: "Error",
          description: "Failed to load banners",
          variant: "destructive",
        })
      } finally {
        setLoading(false)
      }
    }

    fetchBanners()
  }, [toast])

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (file) {
      setImageFile(file)
      const reader = new FileReader()
      reader.onload = () => {
        setImagePreview(reader.result as string)
      }
      reader.readAsDataURL(file)
    }
  }

  const resetForm = () => {
    setFormData({
      title: "",
      description: "",
      link: "",
      active: true,
    })
    setImageFile(null)
    setImagePreview(null)
    setSelectedBanner(null)
    if (fileInputRef.current) {
      fileInputRef.current.value = ""
    }
  }

  const handleAddBanner = () => {
    resetForm()
    setIsDialogOpen(true)
  }

  const handleEditBanner = (id: string, banner: Banner) => {
    setSelectedBanner(id)
    setFormData({
      title: banner.title,
      description: banner.description || "",
      link: banner.link || "",
      active: banner.active,
    })
    setImagePreview(banner.imageUrl)
    setIsDialogOpen(true)
  }

  const handleDeleteBanner = (id: string) => {
    setSelectedBanner(id)
    setIsDeleteDialogOpen(true)
  }

  const handleToggleActive = async (id: string, active: boolean) => {
    try {
      const bannerRef = ref(database, `banners/${id}`)
      await update(bannerRef, { active: !active })

      setBanners((prev) => ({
        ...prev,
        [id]: {
          ...prev[id],
          active: !active,
        },
      }))

      toast({
        title: "Success",
        description: `Banner ${!active ? "activated" : "deactivated"} successfully`,
      })
    } catch (error) {
      console.error("Error toggling banner status:", error)
      toast({
        title: "Error",
        description: "Failed to update banner status",
        variant: "destructive",
      })
    }
  }

  const confirmDeleteBanner = async () => {
    if (!selectedBanner) return

    try {
      // Delete image from storage
      const imageUrl = banners[selectedBanner].imageUrl
      const imagePath = imageUrl.split("?")[0].split("/o/")[1].replace(/%2F/g, "/")
      const decodedPath = decodeURIComponent(imagePath)
      const imageRef = storageRef(storage, decodedPath)
      await deleteObject(imageRef)

      // Delete banner from database
      const bannerRef = ref(database, `banners/${selectedBanner}`)
      await remove(bannerRef)

      // Update state
      setBanners((prev) => {
        const updated = { ...prev }
        delete updated[selectedBanner]
        return updated
      })

      toast({
        title: "Success",
        description: "Banner deleted successfully",
      })
    } catch (error) {
      console.error("Error deleting banner:", error)
      toast({
        title: "Error",
        description: "Failed to delete banner",
        variant: "destructive",
      })
    } finally {
      setIsDeleteDialogOpen(false)
      setSelectedBanner(null)
    }
  }

  const handleSubmit = async () => {
    if (!formData.title) {
      toast({
        title: "Error",
        description: "Title is required",
        variant: "destructive",
      })
      return
    }

    if (!imageFile && !selectedBanner) {
      toast({
        title: "Error",
        description: "Image is required",
        variant: "destructive",
      })
      return
    }

    setIsUploading(true)

    try {
      let imageUrl = selectedBanner ? banners[selectedBanner].imageUrl : ""

      // Upload new image if provided
      if (imageFile) {
        const timestamp = Date.now()
        const imagePath = `banner_images/${timestamp}_${imageFile.name}`
        const imageRef = storageRef(storage, imagePath)
        await uploadBytes(imageRef, imageFile)
        imageUrl = await getDownloadURL(imageRef)
      }

      const bannerData: Banner = {
        id: selectedBanner || "",
        title: formData.title,
        description: formData.description,
        link: formData.link,
        imageUrl,
        active: formData.active,
        createdAt: selectedBanner ? banners[selectedBanner].createdAt : Date.now(),
      }

      if (selectedBanner) {
        // Update existing banner
        const bannerRef = ref(database, `banners/${selectedBanner}`)
        await update(bannerRef, bannerData)

        setBanners((prev) => ({
          ...prev,
          [selectedBanner]: bannerData,
        }))

        toast({
          title: "Success",
          description: "Banner updated successfully",
        })
      } else {
        // Add new banner
        const newBannerRef = push(ref(database, "banners"))
        bannerData.id = newBannerRef.key || ""
        await set(newBannerRef, bannerData)

        setBanners((prev) => ({
          ...prev,
          [bannerData.id]: bannerData,
        }))

        toast({
          title: "Success",
          description: "Banner added successfully",
        })
      }

      setIsDialogOpen(false)
      resetForm()
    } catch (error) {
      console.error("Error saving banner:", error)
      toast({
        title: "Error",
        description: "Failed to save banner",
        variant: "destructive",
      })
    } finally {
      setIsUploading(false)
    }
  }

  return (
    <div className="animate-fade-in space-y-6">
      <div className="flex flex-col justify-between gap-4 md:flex-row md:items-center">
        <div>
          <h1 className="text-3xl font-bold">Banners</h1>
          <p className="text-muted-foreground">Manage your promotional banners</p>
        </div>
        <Button onClick={handleAddBanner}>
          <Plus className="mr-2 h-4 w-4" />
          Add Banner
        </Button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-10">
          <Loader2 className="h-8 w-8 animate-spin text-primary" />
        </div>
      ) : Object.keys(banners).length === 0 ? (
        <Card className="flex flex-col items-center justify-center p-10 text-center">
          <ImageIcon className="mb-4 h-16 w-16 text-muted-foreground" />
          <h3 className="text-lg font-semibold">No banners found</h3>
          <p className="text-muted-foreground">Add your first banner to promote your services</p>
          <Button className="mt-4" onClick={handleAddBanner}>
            <Plus className="mr-2 h-4 w-4" />
            Add Banner
          </Button>
        </Card>
      ) : (
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {Object.entries(banners).map(([id, banner]) => (
            <Card key={id} className="overflow-hidden">
              <div className="relative aspect-video w-full overflow-hidden">
                <img
                  src={banner.imageUrl || "/placeholder.svg"}
                  alt={banner.title}
                  className="h-full w-full object-cover transition-transform duration-300 hover:scale-105"
                />
                {!banner.active && (
                  <div className="absolute inset-0 flex items-center justify-center bg-black/50">
                    <p className="rounded-md bg-black/70 px-3 py-1 text-sm text-white">Inactive</p>
                  </div>
                )}
              </div>
              <CardContent className="p-4">
                <div className="mb-2 flex items-center justify-between">
                  <h3 className="text-lg font-semibold">{banner.title}</h3>
                  <div className="flex items-center space-x-1">
                    <Button variant="ghost" size="icon" onClick={() => handleToggleActive(id, banner.active)}>
                      {banner.active ? <Eye className="h-4 w-4" /> : <EyeOff className="h-4 w-4" />}
                    </Button>
                    <Button variant="ghost" size="icon" onClick={() => handleEditBanner(id, banner)}>
                      <Edit className="h-4 w-4" />
                    </Button>
                    <Button variant="ghost" size="icon" onClick={() => handleDeleteBanner(id)}>
                      <Trash2 className="h-4 w-4 text-destructive" />
                    </Button>
                  </div>
                </div>
                {banner.description && <p className="text-sm text-muted-foreground">{banner.description}</p>}
                {banner.link && (
                  <a
                    href={banner.link}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-2 inline-flex items-center text-xs text-primary hover:underline"
                  >
                    View Link <ExternalLink className="ml-1 h-3 w-3" />
                  </a>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{selectedBanner ? "Edit Banner" : "Add New Banner"}</DialogTitle>
            <DialogDescription>
              {selectedBanner ? "Update your banner information" : "Create a new promotional banner"}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="title">Title</Label>
              <Input
                id="title"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                placeholder="Enter banner title"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="description">Description (Optional)</Label>
              <Textarea
                id="description"
                value={formData.description}
                onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                placeholder="Enter banner description"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="link">Link URL (Optional)</Label>
              <Input
                id="link"
                value={formData.link}
                onChange={(e) => setFormData({ ...formData, link: e.target.value })}
                placeholder="https://example.com"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="image">Banner Image</Label>
              <div className="grid gap-2">
                {imagePreview && (
                  <div className="relative aspect-video overflow-hidden rounded-md border">
                    <img
                      src={imagePreview || "/placeholder.svg"}
                      alt="Preview"
                      className="h-full w-full object-cover"
                    />
                  </div>
                )}
                <Input
                  id="image"
                  type="file"
                  accept="image/*"
                  ref={fileInputRef}
                  onChange={handleFileChange}
                  className="cursor-pointer"
                />
              </div>
            </div>
            <div className="flex items-center space-x-2">
              <Switch
                id="active"
                checked={formData.active}
                onCheckedChange={(checked) => setFormData({ ...formData, active: checked })}
              />
              <Label htmlFor="active">Active</Label>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              Cancel
            </Button>
            <Button onClick={handleSubmit} disabled={isUploading}>
              {isUploading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {isUploading ? "Saving..." : selectedBanner ? "Update Banner" : "Add Banner"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      <AlertDialog open={isDeleteDialogOpen} onOpenChange={setIsDeleteDialogOpen}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Are you sure?</AlertDialogTitle>
            <AlertDialogDescription>
              This action cannot be undone. This will permanently delete the banner and remove its data from the
              database.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancel</AlertDialogCancel>
            <AlertDialogAction onClick={confirmDeleteBanner} className="bg-destructive">
              Delete
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}
