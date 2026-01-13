
'use client';

import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Switch } from '@/components/ui/switch';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Rocket, PlusCircle, MapPin, Trash2, Loader2 as LoaderCircle } from 'lucide-react';
import Link from 'next/link';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { regions, communesByRegion } from '@/lib/locations';
import { useState, useEffect } from 'react';
import type { Venue } from '@/lib/types';
import { useFirestore, useUser, useCollection, useMemoFirebase, addDocumentNonBlocking, deleteDocumentNonBlocking } from '@/firebase';
import { collection, doc, type Firestore } from 'firebase/firestore';
import { useToast } from '@/hooks/use-toast';
import type { User } from 'firebase/auth';

const venueSchema = z.object({
  name: z.string().min(3, 'El nombre debe tener al menos 3 caracteres.'),
  address: z.string().min(5, 'La dirección debe tener al menos 5 caracteres.'),
  region: z.string().min(1, 'Debes seleccionar una región.'),
  commune: z.string().min(1, 'Debes seleccionar una comuna.'),
});

// Componente hijo que renderiza el contenido principal solo cuando el usuario está cargado.
function SettingsContent({ user, firestore }: { user: User, firestore: Firestore }) {
  const [isAddingVenue, setIsAddingVenue] = useState(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const { toast } = useToast();

  const venuesCollectionRef = useMemoFirebase(() => {
    return collection(firestore, 'users', user.uid, 'venues');
  }, [firestore, user.uid]);

  const { data: venues, isLoading: isLoadingVenues } = useCollection<Venue>(venuesCollectionRef);

  // States for notification settings
  const [newBookingsEnabled, setNewBookingsEnabled] = useState(true);
  const [classRemindersEnabled, setClassRemindersEnabled] = useState(true);
  const [cancellationsEnabled, setCancellationsEnabled] = useState(false);
  const [weeklySummaryEnabled, setWeeklySummaryEnabled] = useState(true);

  const form = useForm({
    resolver: zodResolver(venueSchema),
    defaultValues: {
      name: '',
      address: '',
      region: '',
      commune: '',
    },
  });

  const selectedRegion = form.watch('region');

  const onSubmit = async (data: z.infer<typeof venueSchema>) => {
    setIsSubmitting(true);
    
    const newVenue: Omit<Venue, 'id'> = {
      ...data,
      ownerId: user.uid,
    };

    try {
        await addDocumentNonBlocking(firestore, venuesCollectionRef!, newVenue);
        toast({
            title: '¡Sede Añadida!',
            description: `La sede "${data.name}" ha sido guardada.`,
        });
        setIsAddingVenue(false);
        form.reset();
    } catch (error) {
        console.error("Error adding venue:", error);
        toast({
            variant: 'destructive',
            title: 'Error al añadir sede',
            description: 'Hubo un problema al guardar la sede en la base de datos.',
        });
    } finally {
        setIsSubmitting(false);
    }
  };

  const removeVenue = (id: string) => {
    const venueDocRef = doc(firestore, 'users', user.uid, 'venues', id);
    deleteDocumentNonBlocking(firestore, venueDocRef);
    toast({
      title: 'Sede eliminada',
      description: 'La sede ha sido eliminada correctamente.',
    })
  }

  return (
    <>
      <Card>
        <CardHeader>
          <CardTitle className="font-headline">Mis Sedes</CardTitle>
          <CardDescription>
            Administra las ubicaciones donde impartes clases.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-4">
            {isLoadingVenues ? (
                <div className="flex justify-center items-center h-24">
                    <LoaderCircle className="h-6 w-6 animate-spin" />
                </div>
            ) : venues && venues.length > 0 ? (
                venues.map((venue) => (
                    <div key={venue.id} className="flex items-center justify-between space-x-4 rounded-lg border p-4">
                        <div className="flex items-center gap-4">
                        <MapPin className="h-6 w-6 text-primary" />
                        <div className="space-y-0.5">
                            <p className="font-semibold">{venue.name}</p>
                            <p className="text-sm text-muted-foreground">{venue.address}, {venue.commune}</p>
                        </div>
                        </div>
                        <Button variant="ghost" size="icon" onClick={() => removeVenue(venue.id)}>
                            <Trash2 className="h-4 w-4 text-destructive" />
                            <span className="sr-only">Eliminar Sede</span>
                        </Button>
                    </div>
                ))
            ) : (
                !isAddingVenue && <p className="text-sm text-muted-foreground text-center py-4">No has añadido ninguna sede todavía.</p>
            )}
          </div>

          {isAddingVenue ? (
             <Form {...form}>
                <form onSubmit={form.handleSubmit(onSubmit)} className="p-4 border border-dashed rounded-lg space-y-4">
                    <FormField
                        control={form.control}
                        name="name"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Nombre de la Sede</FormLabel>
                                <FormControl>
                                    <Input placeholder="Ej: Gimnasio FitPro" {...field} />
                                </FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                    <FormField
                        control={form.control}
                        name="address"
                        render={({ field }) => (
                            <FormItem>
                                <FormLabel>Dirección</FormLabel>
                                <FormControl>
                                    <Input placeholder="Ej: Av. Principal 123" {...field} />
                                </FormControl>
                                <FormMessage />
                            </FormItem>
                        )}
                    />
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        <FormField
                            control={form.control}
                            name="region"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Región</FormLabel>
                                    <Select onValueChange={field.onChange} defaultValue={field.value}>
                                    <FormControl>
                                        <SelectTrigger>
                                        <SelectValue placeholder="Selecciona una región" />
                                        </SelectTrigger>
                                    </FormControl>
                                    <SelectContent>
                                        {regions.map(r => <SelectItem key={r.value} value={r.value}>{r.label}</SelectItem>)}
                                    </SelectContent>
                                    </Select>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                        <FormField
                            control={form.control}
                            name="commune"
                            render={({ field }) => (
                                <FormItem>
                                    <FormLabel>Comuna</FormLabel>
                                    <Select onValueChange={field.onChange} defaultValue={field.value} disabled={!selectedRegion}>
                                    <FormControl>
                                        <SelectTrigger>
                                            <SelectValue placeholder="Selecciona una comuna" />
                                        </SelectTrigger>
                                    </FormControl>
                                    <SelectContent>
                                        {selectedRegion && communesByRegion[selectedRegion]?.map(c => <SelectItem key={c.value} value={c.value}>{c.label}</SelectItem>)}
                                    </SelectContent>
                                    </Select>
                                    <FormMessage />
                                </FormItem>
                            )}
                        />
                    </div>
                    <div className="flex justify-end gap-2">
                         <Button variant="ghost" type="button" onClick={() => setIsAddingVenue(false)} disabled={isSubmitting}>Cancelar</Button>
                         <Button type="submit" disabled={isSubmitting}>
                            {isSubmitting && <LoaderCircle className="mr-2 h-4 w-4 animate-spin" />}
                            Guardar Sede
                         </Button>
                    </div>
                </form>
            </Form>
          ) : (
            <Button variant="outline" className="w-full" onClick={() => setIsAddingVenue(true)}>
                <PlusCircle className="mr-2 h-4 w-4" />
                Añadir nueva sede
            </Button>
          )}

        </CardContent>
      </Card>


      <Card>
        <CardHeader>
          <CardTitle className="font-headline">Configuración de Notificaciones</CardTitle>
          <CardDescription>
            Administra tus notificaciones de Plads Pro.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className="flex items-center justify-between space-x-4 rounded-lg border p-4">
            <div className="space-y-0.5">
              <Label htmlFor="new-bookings-email" className="text-base">
                Nuevo agendamiento
              </Label>
              <p className="text-sm text-muted-foreground">
                Recibe notificaciones sobre nuevos cupos agendados.
              </p>
            </div>
            <div className='flex items-center gap-4'>
                <Select defaultValue="immediate" disabled={!newBookingsEnabled}>
                    <SelectTrigger className="w-[180px]">
                        <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="immediate">Inmediatamente</SelectItem>
                        <SelectItem value="hourly">Resumen cada hora</SelectItem>
                        <SelectItem value="daily">Resumen diario</SelectItem>
                    </SelectContent>
                </Select>
                <Switch 
                    id="new-bookings-email" 
                    checked={newBookingsEnabled}
                    onCheckedChange={setNewBookingsEnabled}
                />
            </div>
          </div>
          <div className="flex items-center justify-between space-x-4 rounded-lg border p-4">
            <div className="space-y-0.5">
              <Label htmlFor="class-reminders-push" className="text-base">
                Recordatorios de Clases
              </Label>
              <p className="text-sm text-muted-foreground">
                Define cuándo recibir recordatorios de tus próximas clases.
              </p>
            </div>
            <div className='flex items-center gap-4'>
                <Select defaultValue="24" disabled={!classRemindersEnabled}>
                    <SelectTrigger className="w-[180px]">
                        <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="24">24 horas antes</SelectItem>
                        <SelectItem value="12">12 horas antes</SelectItem>
                        <SelectItem value="6">6 horas antes</SelectItem>
                        <SelectItem value="1">1 hora antes</SelectItem>
                    </SelectContent>
                </Select>
                <Switch 
                    id="class-reminders-push" 
                    checked={classRemindersEnabled}
                    onCheckedChange={setClassRemindersEnabled}
                />
            </div>
          </div>
          <div className="flex items-center justify-between space-x-4 rounded-lg border p-4">
            <div className="space-y-0.5">
              <Label htmlFor="cancellations-email" className="text-base">
                Cancelaciones
              </Label>
              <p className="text-sm text-muted-foreground">
                Notifícame cuando se cancele un cupo agendado.
              </p>
            </div>
             <div className='flex items-center gap-4'>
                <Select defaultValue="immediate" disabled={!cancellationsEnabled}>
                    <SelectTrigger className="w-[180px]">
                        <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                        <SelectItem value="immediate">Inmediatamente</SelectItem>
                        <SelectItem value="hourly">Resumen cada hora</SelectItem>
                    </SelectContent>
                </Select>
                <Switch 
                    id="cancellations-email"
                    checked={cancellationsEnabled}
                    onCheckedChange={setCancellationsEnabled}
                />
            </div>
          </div>
          <div className="flex items-center justify-between space-x-4 rounded-lg border p-4">
            <div className="space-y-0.5">
              <Label htmlFor="weekly-summary" className="text-base">
                Análisis Semanal
              </Label>
              <p className="text-sm text-muted-foreground">
              Envía un correo semanal con tus métricas clave de rendimiento.
              </p>
            </div>
            <Switch 
                id="weekly-summary" 
                checked={weeklySummaryEnabled}
                onCheckedChange={setWeeklySummaryEnabled}
            />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="font-headline">Cuenta</CardTitle>
          <CardDescription>Gestión de tu cuenta.</CardDescription>
        </CardHeader>
        <CardContent>
          <Button variant="destructive">Eliminar cuenta</Button>
          <p className="text-sm text-muted-foreground mt-2">
            Elimina permanentemente tu cuenta y todos los datos asociados. Esta acción no se puede deshacer.
          </p>
        </CardContent>
      </Card>
    </>
  );
}


export default function SettingsPage() {
    const { user, isUserLoading } = useUser();
    const firestore = useFirestore();
    const [isClient, setIsClient] = useState(false);
  
    useEffect(() => {
      setIsClient(true);
    }, []);
  
    if (!isClient || isUserLoading || !firestore) {
      return (
        <div className="flex h-full w-full items-center justify-center p-16">
          <LoaderCircle className="h-8 w-8 animate-spin" />
        </div>
      );
    }
  
    if (!user) {
       return (
        <div className="flex flex-col gap-8">
          <h1 className="font-headline text-3xl font-semibold">Configuraciones</h1>
          <Card>
             <CardHeader>
              <CardTitle className="font-headline">Mis Sedes</CardTitle>
            </CardHeader>
             <CardContent>
              <div className="flex h-24 items-center justify-center">
                <p className='text-muted-foreground'>Inicia sesión para ver tus configuraciones.</p>
              </div>
            </CardContent>
          </Card>
        </div>
       )
    }

    return (
        <div className="flex flex-col gap-8">
            <h1 className="font-headline text-3xl font-semibold">Configuraciones</h1>
            <Card>
                <CardHeader>
                    <CardTitle className="font-headline">Plan Actual</CardTitle>
                    <CardDescription>
                        Actualmente estás en el plan Gratuito. Mejora a Pro para desbloquear más funciones.
                    </CardDescription>
                </CardHeader>
                <CardContent>
                    <Link href="/pro-plan">
                        <Button>
                            <Rocket className="mr-2 h-4 w-4" />
                            Mejorar a Pro
                        </Button>
                    </Link>
                </CardContent>
            </Card>
            <SettingsContent user={user} firestore={firestore} />
        </div>
      );
}
