'use client';

import { useState } from 'react';
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from '@/components/ui/card';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { Button } from '@/components/ui/button';
import { Edit, Instagram, Rocket, Globe, User, Star, PlusCircle, CheckCircle } from 'lucide-react';
import Link from 'next/link';
import VideoGallery from '@/components/video-gallery';
import { TikTokIcon, FacebookIcon, LinkedinIcon } from '@/components/ui/icons';
import { StarRating } from '@/components/ui/star-rating';
import type { InstructorProfile } from '@/lib/types';
import { useUser, useFirestore, useDoc, useMemoFirebase } from '@/firebase';
import { doc } from 'firebase/firestore';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import EditProfileForm from '@/components/edit-profile-form';
import EditSocialsForm from '@/components/edit-socials-form';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import ProfileForm from '@/components/profile-form';

export default function ProfilePage() {
  const { user } = useUser();
  const firestore = useFirestore();
  const [isEditDialogOpen, setIsEditDialogOpen] = useState(false);
  const [isSocialsDialogOpen, setIsSocialsDialogOpen] = useState(false);

  const profileRef = useMemoFirebase(() => {
    if (!user) return null;
    return doc(firestore!, 'users', user.uid, 'instructorProfile', 'profile');
  }, [user, firestore]);

  const { data: profile, isLoading: isLoadingProfile } = useDoc<InstructorProfile>(profileRef);
  
  const displayName = profile?.name || user?.displayName || 'Nombre de Usuario';
  const displayCategory = profile?.category || 'Sin categoría';

  return (
    <div className="flex flex-col gap-8">
      <h1 className="font-headline text-3xl font-semibold">Perfil</h1>

      <div className="grid grid-cols-1 gap-8 lg:grid-cols-3">
        <div className="lg:col-span-1 flex flex-col gap-8">
          <Card>
            <CardHeader className="flex flex-col items-center text-center">
              <Avatar className="h-24 w-24 mb-4">
                 {user?.photoURL && <AvatarImage src={user.photoURL} alt={displayName} />}
                <AvatarFallback className="text-3xl">{displayName.charAt(0) || 'U'}</AvatarFallback>
              </Avatar>
              <CardTitle className="font-headline text-2xl">{displayName}</CardTitle>
              <CardDescription>
                Instructor/a de {displayCategory}
              </CardDescription>
              <div className="flex items-center gap-2 pt-2">
                <StarRating rating={0} />
                <span className="text-sm font-semibold text-muted-foreground">(Sin reseñas)</span>
              </div>
            </CardHeader>
            <CardContent>
               <Dialog open={isEditDialogOpen} onOpenChange={setIsEditDialogOpen}>
                <DialogTrigger asChild>
                    <Button variant="outline" className="w-full">
                        <Edit className="mr-2 h-4 w-4" />
                        Editar Perfil
                    </Button>
                </DialogTrigger>
                <DialogContent className="sm:max-w-xl">
                    <DialogHeader>
                    <DialogTitle>Editar Perfil Profesional</DialogTitle>
                    <DialogDescription>
                        Esta es la información que verán los estudiantes sobre ti.
                    </DialogDescription>
                    </DialogHeader>
                    <EditProfileForm 
                        currentProfile={profile} 
                        onSave={() => setIsEditDialogOpen(false)} 
                    />
                </DialogContent>
               </Dialog>
            </CardContent>
          </Card>
           <Card>
            <CardHeader>
              <CardTitle className="font-headline text-lg">Redes Sociales</CardTitle>
              <CardDescription>Conecta con tus estudiantes.</CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className='flex items-center gap-2'>
                <Button asChild variant="outline" size="icon" disabled={!profile?.instagramUrl} className="disabled:opacity-50 disabled:cursor-not-allowed">
                    <Link href={profile?.instagramUrl || '#'} target="_blank" aria-label="Instagram"><Instagram className="h-5 w-5" /></Link>
                </Button>
                <Button asChild variant="outline" size="icon" disabled={!profile?.tiktokUrl} className="disabled:opacity-50 disabled:cursor-not-allowed">
                    <Link href={profile?.tiktokUrl || '#'} target="_blank" aria-label="TikTok"><TikTokIcon className="h-5 w-5" /></Link>
                </Button>
                <Button asChild variant="outline" size="icon" disabled={!profile?.facebookUrl} className="disabled:opacity-50 disabled:cursor-not-allowed">
                    <Link href={profile?.facebookUrl || '#'} target="_blank" aria-label="Facebook"><FacebookIcon className="h-5 w-5" /></Link>
                </Button>
                <Button asChild variant="outline" size="icon" disabled={!profile?.linkedinUrl} className="disabled:opacity-50 disabled:cursor-not-allowed">
                    <Link href={profile?.linkedinUrl || '#'} target="_blank" aria-label="LinkedIn"><LinkedinIcon className="h-5 w-5" /></Link>
                </Button>
                 <Button asChild variant="outline" size="icon" disabled={!profile?.websiteUrl} className="disabled:opacity-50 disabled:cursor-not-allowed">
                    <Link href={profile?.websiteUrl || '#'} target="_blank" aria-label="Website"><Globe className="h-5 w-5" /></Link>
                </Button>
              </div>

               <Dialog open={isSocialsDialogOpen} onOpenChange={setIsSocialsDialogOpen}>
                <DialogTrigger asChild>
                  <Button variant="outline" size="sm" className="w-full">
                      <Edit className="mr-2 h-4 w-4" />
                      Editar Redes
                  </Button>
                </DialogTrigger>
                <DialogContent className="sm:max-w-md">
                    <DialogHeader>
                        <DialogTitle>Editar Redes Sociales</DialogTitle>
                        <DialogDescription>
                            Añade tus enlaces para que los estudiantes puedan encontrarte.
                        </DialogDescription>
                    </DialogHeader>
                    <EditSocialsForm
                        currentProfile={profile}
                        onSave={() => setIsSocialsDialogOpen(false)}
                    />
                </DialogContent>
               </Dialog>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="font-headline text-lg">Plan Actual</CardTitle>
              <CardDescription>Actualmente estás en el plan Gratuito.</CardDescription>
            </CardHeader>
            <CardContent>
              <Link href="/pro-plan" className="w-full">
                <Button className="w-full">
                  <Rocket className="mr-2 h-4 w-4" />
                  Mejorar a Pro
                </Button>
              </Link>
            </CardContent>
          </Card>
        </div>
        <div className="lg:col-span-2 flex flex-col gap-8">
           <Card>
            <CardHeader>
              <CardTitle className="font-headline">Especialidades</CardTitle>
              <CardDescription>
                Las categorías, estilos y públicos que defines en tu perfil.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
                 <div>
                    <h4 className="font-semibold text-sm mb-2">Estilos</h4>
                     <div className="flex flex-wrap gap-2">
                        {profile?.styles && profile.styles.length > 0 ? (
                            profile.styles.map(style => <Badge key={style} variant="secondary">{style}</Badge>)
                        ) : (
                            <p className="text-sm text-muted-foreground">Aún no has definido tus estilos.</p>
                        )}
                    </div>
                </div>
                <Separator />
                <div>
                    <h4 className="font-semibold text-sm mb-2">Público</h4>
                     <div className="flex flex-wrap gap-2">
                        {profile?.audiences && profile.audiences.length > 0 ? (
                           profile.audiences.map(audience => <Badge key={audience} variant="outline">{audience}</Badge>)
                        ) : (
                            <p className="text-sm text-muted-foreground">Aún no has definido tu público.</p>
                        )}
                    </div>
                </div>
                 <Separator />
                <div>
                    <h4 className="font-semibold text-sm mb-2">Coaching</h4>
                    <div className="flex items-center gap-2">
                        {profile?.isCoaching ? (
                            <Badge className='bg-green-100 text-green-800 hover:bg-green-200 dark:bg-green-900/50 dark:text-green-300'>
                                <CheckCircle className="mr-1 h-3 w-3" />
                                Ofrece Coaching
                            </Badge>
                        ) : (
                             <p className="text-sm text-muted-foreground">No ofreces coaching actualmente.</p>
                        )}
                    </div>
                </div>
            </CardContent>
          </Card>
           <Card>
            <CardHeader>
              <CardTitle className="font-headline">Sobre Mí</CardTitle>
              <CardDescription>
                Tu biografía profesional.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4 text-sm text-muted-foreground">
              {isLoadingProfile ? (
                 <p>Cargando perfil...</p>
              ) : profile?.bio ? (
                <p className="whitespace-pre-wrap">{profile.bio}</p>
              ) : (
                <p>
                  Aún no has añadido una biografía. Edita tu perfil para contarle a los estudiantes sobre ti, tu experiencia y tu estilo de enseñanza.
                </p>
              )}
            </CardContent>
          </Card>
           <Card>
            <CardHeader>
              <CardTitle className="font-headline">Galería de Videos</CardTitle>
              <CardDescription>
                Sube hasta 5 videos para mostrar tu talento a potenciales estudiantes.
              </CardDescription>
            </CardHeader>
            <CardContent>
                <VideoGallery />
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="font-headline">Reseñas de Estudiantes</CardTitle>
              <CardDescription>
                Opiniones de estudiantes que han tomado clases.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6 text-center text-muted-foreground py-10">
                <p>Aún no tienes reseñas.</p>
            </CardContent>
          </Card>
          <Card>
            <CardHeader>
              <CardTitle className="font-headline">Asistente de IA</CardTitle>
              <CardDescription>
                Deja a nuestra IA ayudarte a crear un perfil de usuario llamativo.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <ProfileForm />
            </CardContent>
          </Card>
        </div>
      </div>
    </div>
  );
}
