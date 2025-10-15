"use client";

import { useState } from "react";
import { FadeIn } from "./FadeIn";

interface FormData {
  name: string;
  businessName: string;
  phoneNumber: string;
  businessAddress: string;
  instagram: string;
  message: string;
}

interface FormErrors {
  name?: string;
  businessName?: string;
  phoneNumber?: string;
  message?: string;
}

export function InquiryForm() {
  const [formData, setFormData] = useState<FormData>({
    name: "",
    businessName: "",
    phoneNumber: "",
    businessAddress: "",
    instagram: "",
    message: "",
  });

  const [errors, setErrors] = useState<FormErrors>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [submitStatus, setSubmitStatus] = useState<
    "idle" | "success" | "error"
  >("idle");

  const validateForm = (): boolean => {
    const newErrors: FormErrors = {};

    if (!formData.name.trim()) {
      newErrors.name = "Name is required";
    }

    if (!formData.businessName.trim()) {
      newErrors.businessName = "Business name is required";
    }

    if (!formData.phoneNumber.trim()) {
      newErrors.phoneNumber = "Phone number is required";
    } else if (
      !/^[\+]?[1-9][\d]{0,15}$/.test(
        formData.phoneNumber.replace(/[\s\-\(\)]/g, "")
      )
    ) {
      newErrors.phoneNumber = "Please enter a valid phone number";
    }

    if (!formData.message.trim()) {
      newErrors.message = "Message is required";
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!validateForm()) {
      return;
    }

    setIsSubmitting(true);
    setSubmitStatus("idle");

    try {
      const response = await fetch("/api/inquiry", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(formData),
      });

      if (response.ok) {
        setSubmitStatus("success");
        setFormData({
          name: "",
          businessName: "",
          phoneNumber: "",
          businessAddress: "",
          instagram: "",
          message: "",
        });
      } else {
        setSubmitStatus("error");
      }
    } catch (error) {
      console.error("Error submitting form:", error);
      setSubmitStatus("error");
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target;
    setFormData((prev) => ({ ...prev, [name]: value }));

    // Clear error when user starts typing
    if (errors[name as keyof FormErrors]) {
      setErrors((prev) => ({ ...prev, [name]: undefined }));
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <FadeIn delay={0.1}>
        <h2 className="text-[24px] md:text-[28px] font-bold mb-8 text-center">
          Send us your inquiry
        </h2>
      </FadeIn>

      <FadeIn delay={0.15}>
        <form onSubmit={handleSubmit} className="space-y-6">
          {/* Name */}
          <div>
            <label
              htmlFor="name"
              className="block text-[16px] md:text-[18px] font-bold mb-2"
            >
              Name *
            </label>
            <input
              type="text"
              id="name"
              name="name"
              value={formData.name}
              onChange={handleChange}
              className={`w-full px-4 py-3 bg-soft-black border-2 rounded-lg text-soft-white placeholder-opacity-50 focus:outline-none focus:ring-2 focus:ring-soft-white transition-colors ${
                errors.name
                  ? "border-red-500"
                  : "border-hairline-gray hover:border-soft-white"
              }`}
              placeholder="Your full name"
            />
            {errors.name && (
              <p className="text-red-500 text-sm mt-1">{errors.name}</p>
            )}
          </div>

          {/* Business Name */}
          <div>
            <label
              htmlFor="businessName"
              className="block text-[16px] md:text-[18px] font-bold mb-2"
            >
              Business Name *
            </label>
            <input
              type="text"
              id="businessName"
              name="businessName"
              value={formData.businessName}
              onChange={handleChange}
              className={`w-full px-4 py-3 bg-soft-black border-2 rounded-lg text-soft-white placeholder-opacity-50 focus:outline-none focus:ring-2 focus:ring-soft-white transition-colors ${
                errors.businessName
                  ? "border-red-500"
                  : "border-hairline-gray hover:border-soft-white"
              }`}
              placeholder="Your business name"
            />
            {errors.businessName && (
              <p className="text-red-500 text-sm mt-1">{errors.businessName}</p>
            )}
          </div>

          {/* Phone Number */}
          <div>
            <label
              htmlFor="phoneNumber"
              className="block text-[16px] md:text-[18px] font-bold mb-2"
            >
              Phone Number *
            </label>
            <input
              type="tel"
              id="phoneNumber"
              name="phoneNumber"
              value={formData.phoneNumber}
              onChange={handleChange}
              className={`w-full px-4 py-3 bg-soft-black border-2 rounded-lg text-soft-white placeholder-opacity-50 focus:outline-none focus:ring-2 focus:ring-soft-white transition-colors ${
                errors.phoneNumber
                  ? "border-red-500"
                  : "border-hairline-gray hover:border-soft-white"
              }`}
              placeholder="+1 (555) 123-4567"
            />
            {errors.phoneNumber && (
              <p className="text-red-500 text-sm mt-1">{errors.phoneNumber}</p>
            )}
          </div>

          {/* Business Address */}
          <div>
            <label
              htmlFor="businessAddress"
              className="block text-[16px] md:text-[18px] font-bold mb-2"
            >
              Business Address
            </label>
            <input
              type="text"
              id="businessAddress"
              name="businessAddress"
              value={formData.businessAddress}
              onChange={handleChange}
              className="w-full px-4 py-3 bg-soft-black border-2 border-hairline-gray rounded-lg text-soft-white placeholder-opacity-50 focus:outline-none focus:ring-2 focus:ring-soft-white hover:border-soft-white transition-colors"
              placeholder="Your business address (optional)"
            />
          </div>

          {/* Instagram */}
          <div>
            <label
              htmlFor="instagram"
              className="block text-[16px] md:text-[18px] font-bold mb-2"
            >
              Instagram
            </label>
            <input
              type="text"
              id="instagram"
              name="instagram"
              value={formData.instagram}
              onChange={handleChange}
              className="w-full px-4 py-3 bg-soft-black border-2 border-hairline-gray rounded-lg text-soft-white placeholder-opacity-50 focus:outline-none focus:ring-2 focus:ring-soft-white hover:border-soft-white transition-colors"
              placeholder="@your_instagram_handle (optional)"
            />
          </div>

          {/* Message */}
          <div>
            <label
              htmlFor="message"
              className="block text-[16px] md:text-[18px] font-bold mb-2"
            >
              Message *
            </label>
            <textarea
              id="message"
              name="message"
              value={formData.message}
              onChange={handleChange}
              rows={6}
              className={`w-full px-4 py-3 bg-soft-black border-2 rounded-lg text-soft-white placeholder-opacity-50 focus:outline-none focus:ring-2 focus:ring-soft-white transition-colors resize-none ${
                errors.message
                  ? "border-red-500"
                  : "border-hairline-gray hover:border-soft-white"
              }`}
              placeholder="Tell us about your project, goals, and how we can help..."
            />
            {errors.message && (
              <p className="text-red-500 text-sm mt-1">{errors.message}</p>
            )}
          </div>

          {/* Submit Button */}
          <div className="pt-4">
            <button
              type="submit"
              disabled={isSubmitting}
              className={`w-full py-4 px-8 rounded-lg text-[18px] md:text-[20px] font-bold transition-colors duration-200 ${
                isSubmitting
                  ? "bg-hairline-gray text-soft-white cursor-not-allowed"
                  : "bg-soft-white text-soft-black hover:bg-pure-white"
              }`}
            >
              {isSubmitting ? "Sending..." : "Send Inquiry"}
            </button>
          </div>

          {/* Status Messages */}
          {submitStatus === "success" && (
            <FadeIn>
              <div className="text-center py-4">
                <p className="text-green-500 text-[16px] md:text-[18px] font-bold">
                  Thank you! Your inquiry has been sent successfully.
                </p>
                <p className="text-soft-white text-sm mt-2 opacity-70">
                  We&apos;ll get back to you within 24 hours.
                </p>
              </div>
            </FadeIn>
          )}

          {submitStatus === "error" && (
            <FadeIn>
              <div className="text-center py-4">
                <p className="text-red-500 text-[16px] md:text-[18px] font-bold">
                  Sorry, there was an error sending your inquiry.
                </p>
                <p className="text-soft-white text-sm mt-2 opacity-70">
                  Please try again or contact us directly.
                </p>
              </div>
            </FadeIn>
          )}
        </form>
      </FadeIn>
    </div>
  );
}
