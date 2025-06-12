"use client";
import { useState, useEffect } from "react";
import { ref, get, set, update, remove } from "firebase/database";
import { database } from "@/lib/firebase";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useToast } from "@/components/ui/use-toast";
import { Loader2, Trash, Edit, Plus } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

interface FAQ {
  question: string;
  answer: string;
}

interface FAQs {
  hardware: FAQ[];
  software: FAQ[];
}

export default function FAQPage() {
  const [loading, setLoading] = useState(false);
  const [faqs, setFaqs] = useState<FAQs>({ hardware: [], software: [] });
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [faqCategory, setFaqCategory] = useState<keyof FAQs>("hardware");
  const [faqQuestion, setFaqQuestion] = useState("");
  const [faqAnswer, setFaqAnswer] = useState("");
  const [editIndex, setEditIndex] = useState<number | null>(null);
  const { toast } = useToast();

  useEffect(() => {
    const fetchFAQs = async () => {
      try {
        setLoading(true);
        const faqsRef = ref(database, "faqs");
        const snapshot = await get(faqsRef);
        if (snapshot.exists()) {
          setFaqs(snapshot.val());
        }
      } catch (error) {
        console.error("Error fetching FAQs:", error);
        toast({
          title: "Error",
          description: "Failed to load FAQs",
          variant: "destructive",
        });
      } finally {
        setLoading(false);
      }
    };

    fetchFAQs();
  }, [toast]);

  const handleAddFAQ = async () => {
    if (!faqQuestion || !faqAnswer) {
      toast({
        title: "Error",
        description: "Question and Answer are required",
        variant: "destructive",
      });
      return;
    }

    try {
      setLoading(true);
      const faqsRef = ref(database, `faqs/${faqCategory}`);
      const newFAQs = [...faqs[faqCategory], { question: faqQuestion, answer: faqAnswer }];
      await set(faqsRef, newFAQs);

      setFaqs((prev) => ({
        ...prev,
        [faqCategory]: newFAQs,
      }));

      toast({
        title: "Success",
        description: "FAQ added successfully",
      });

      resetForm();
    } catch (error) {
      console.error("Error adding FAQ:", error);
      toast({
        title: "Error",
        description: "Failed to add FAQ",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleEditFAQ = (index: number) => {
    const faq = faqs[faqCategory][index];
    setFaqQuestion(faq.question);
    setFaqAnswer(faq.answer);
    setEditIndex(index);
    setIsDialogOpen(true);
  };

  const handleUpdateFAQ = async () => {
    if (!faqQuestion || !faqAnswer || editIndex === null) {
      toast({
        title: "Error",
        description: "Question and Answer are required",
        variant: "destructive",
      });
      return;
    }

    try {
      setLoading(true);
      const faqsRef = ref(database, `faqs/${faqCategory}/${editIndex}`);
      const updatedFAQs = faqs[faqCategory].map((faq, index) =>
        index === editIndex ? { question: faqQuestion, answer: faqAnswer } : faq
      );
      await update(faqsRef, { question: faqQuestion, answer: faqAnswer });

      setFaqs((prev) => ({
        ...prev,
        [faqCategory]: updatedFAQs,
      }));

      toast({
        title: "Success",
        description: "FAQ updated successfully",
      });

      resetForm();
    } catch (error) {
      console.error("Error updating FAQ:", error);
      toast({
        title: "Error",
        description: "Failed to update FAQ",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteFAQ = async (index: number) => {
    try {
      setLoading(true);
      const faqsRef = ref(database, `faqs/${faqCategory}/${index}`);
      const updatedFAQs = faqs[faqCategory].filter((_, i) => i !== index);
      await remove(faqsRef);

      setFaqs((prev) => ({
        ...prev,
        [faqCategory]: updatedFAQs,
      }));

      toast({
        title: "Success",
        description: "FAQ deleted successfully",
      });
    } catch (error) {
      console.error("Error deleting FAQ:", error);
      toast({
        title: "Error",
        description: "Failed to delete FAQ",
        variant: "destructive",
      });
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFaqQuestion("");
    setFaqAnswer("");
    setEditIndex(null);
    setIsDialogOpen(false);
  };

  return (
    <div className="animate-fade-in space-y-6">
      <div>
        <h1 className="text-3xl font-bold">FAQ Management</h1>
        <p className="text-muted-foreground">Manage FAQs for different categories</p>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {(["hardware", "software"] as (keyof FAQs)[]).map((category) => (
          <Card key={category}>
            <CardHeader>
              <CardTitle className="flex items-center">
                {category.charAt(0).toUpperCase() + category.slice(1)} Problems
              </CardTitle>
              <CardDescription>View and manage FAQs</CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-4">
                  <Loader2 className="h-6 w-6 animate-spin text-primary" />
                </div>
              ) : (
                <div className="space-y-4">
                  {faqs[category].map((faq, index) => (
                    <div key={index} className="rounded-md border p-4">
                      <div className="mb-2 font-semibold">{faq.question}</div>
                      <div className="text-sm text-muted-foreground">{faq.answer}</div>
                      <div className="mt-2 flex justify-end space-x-2">
                        <Button variant="outline" size="sm" onClick={() => handleEditFAQ(index)}>
                          <Edit className="mr-2 h-4 w-4" />
                          Edit
                        </Button>
                        <Button variant="destructive" size="sm" onClick={() => handleDeleteFAQ(index)}>
                          <Trash className="mr-2 h-4 w-4" />
                          Delete
                        </Button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </CardContent>
            <CardFooter>
              <Button
                onClick={() => {
                  setFaqCategory(category);
                  setIsDialogOpen(true);
                }}
              >
                <Plus className="mr-2 h-4 w-4" />
                Add FAQ
              </Button>
            </CardFooter>
          </Card>
        ))}
      </div>

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>{editIndex !== null ? "Edit FAQ" : "Add FAQ"}</DialogTitle>
            <DialogDescription>
              {editIndex !== null ? "Update the FAQ details" : "Enter the FAQ details"}
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="faq-question">Question</Label>
              <Input
                id="faq-question"
                type="text"
                value={faqQuestion}
                onChange={(e) => setFaqQuestion(e.target.value)}
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="faq-answer">Answer</Label>
              <Input
                id="faq-answer"
                type="text"
                value={faqAnswer}
                onChange={(e) => setFaqAnswer(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={resetForm}>
              Cancel
            </Button>
            <Button onClick={editIndex !== null ? handleUpdateFAQ : handleAddFAQ} disabled={loading}>
              {loading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
              {loading ? "Saving..." : editIndex !== null ? "Update FAQ" : "Add FAQ"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
