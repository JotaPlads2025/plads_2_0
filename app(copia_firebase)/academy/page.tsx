
'use client';

import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import * as z from 'zod';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import {
  Form,
  FormControl,
  FormDescription,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { Button } from '@/components/ui/button';
import { Loader2, PlusCircle, Trash2, Users } from 'lucide-react';
import { Separator } from '@/components/ui/separator';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { useToast } from '@/hooks/use-toast';
import type { Academy } from '@/lib/types';
import { useUser } from '@/firebase';

// Dummy data for instructors
const instructors = [
  { id: 'instr-1', name: 'Carlos Ruiz', avatar: 'https://i.imgur.com/8bZ3vA8.jpeg' },
  { id: 'instr-2', name: 'Ana Jaramillo', avatar: 'https://i.imgur.com/sC0tJ8e.jpeg' },
  { id: 'instr-3', name: 'David Toro', avatar: 'https://i.imgur.com/A6j4VzT.jpeg' },
];

const academySchema = z.object({
  name: z.string().min(3, 'El nombre debe tener al menos 3 caracteres.'),
  description: z.string().min(20, 'La descripción debe tener al menos 20 caracteres.'),
});

export default function AcademyPage() {
  const { toast } = useToast();
  const { user } = useUser();
  const [academy, setAcademy] = useState<Academy | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isSaving, setIsSaving] = useState(false);

  const form = useForm<z.infer<typeof academySchema>>({
    resolver: zodResolver(academySchema),
    defaultValues: {
      name: '',
      description: '',
    },
  });

  useEffect(() => {
    // Simulate fetching academy data
    const storedAcademy = localStorage.getItem('plads-pro-academy');
    if (storedAcademy) {
      const parsedAcademy: Academy = JSON.parse(storedAcademy);
      setAcademy(parsedAcademy);
      form.reset({
        name: parsedAcademy.name,
        description: parsedAcademy.description,
      });
    }
    setIsLoading(false);
  }, [form]);

  const onSubmit = (data: z.infer<typeof academySchema>) => {
    setIsSaving(true);
    console.log('Saving academy data:', data);

    const newAcademyData: Academy = {
      id: academy?.id || `acad-${Date.now()}`,
      ownerId: user?.uid || 'user-placeholder',
      instructorIds: academy?.instructorIds || [user?.uid || 'user-placeholder'],
      ...data,
    };
    
    // Simulate saving to backend
    setTimeout(() => {
      localStorage.setItem('plads-pro-academy', JSON.stringify(newAcademyData));
      setAcademy(newAcademyData);
      setIsSaving(false);
      toast({
        title: '¡Academia Actualizada!',
        description: 'La información de tu academia ha sido guardada.',
      });
    }, 1000);
  };

  if (isLoading) {
    return (
        <div className="flex h-full w-full items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin" />
        </div>
    );
  }

  return (
    <div className="flex flex-col gap-8">
      <h1 className="font-headline text-3xl font-semibold">Mi Academia</h1>

      <Card>
        <CardHeader>
          <CardTitle>Información de la Academia</CardTitle>
          <CardDescription>
            {academy 
              ? 'Edita la información pública de tu academia.' 
              : 'Crea tu academia para agrupar a tus instructores y clases en un solo lugar.'}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Form {...form}>
            <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-8">
              <FormField
                control={form.control}
                name="name"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Nombre de la Academia</FormLabel>
                    <FormControl>
                      <Input placeholder="Ej: Academia de Baile FuegoLatino" {...field} />
                    </FormControl>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <FormField
                control={form.control}
                name="description"
                render={({ field }) => (
                  <FormItem>
                    <FormLabel>Descripción</FormLabel>
                    <FormControl>
                      <Textarea
                        placeholder="Describe la misión, visión y lo que hace especial a tu academia."
                        className="resize-y"
                        rows={5}
                        {...field}
                      />
                    </FormControl>
                    <FormDescription>
                      Esta descripción aparecerá en tu perfil público de la academia.
                    </FormDescription>
                    <FormMessage />
                  </FormItem>
                )}
              />
              <Button type="submit" disabled={isSaving}>
                {isSaving && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                {academy ? 'Guardar Cambios' : 'Crear Academia'}
              </Button>
            </form>
          </Form>
        </CardContent>
      </Card>
      
      {academy && (
        <Card>
            <CardHeader>
                <CardTitle className="flex items-center gap-2"><Users /> Instructores</CardTitle>
                <CardDescription>
                    Administra los instructores que forman parte de tu academia.
                </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
                 <div className="space-y-4">
                    {instructors.map((instructor) => (
                    <div key={instructor.id} className="flex items-center justify-between space-x-4 rounded-lg border p-4">
                        <div className="flex items-center gap-4">
                            <Avatar className="h-10 w-10">
                                <AvatarImage src={instructor.avatar} />
                                <AvatarFallback>{instructor.name.charAt(0)}</AvatarFallback>
                            </Avatar>
                            <p className="font-semibold">{instructor.name}</p>
                        </div>
                        <Button variant="ghost" size="icon" className="text-destructive hover:bg-destructive/10">
                            <Trash2 className="h-4 w-4" />
                            <span className="sr-only">Eliminar Instructor</span>
                        </Button>
                    </div>
                    ))}
                 </div>
                 <Separator />
                 <Button variant="outline" className="w-full">
                    <PlusCircle className="mr-2 h-4 w-4" />
                    Invitar Instructor
                </Button>
            </CardContent>
        </Card>
      )}

    </div>
  );
}
