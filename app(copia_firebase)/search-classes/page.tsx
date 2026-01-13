
"use client";

import { useState, useMemo, useEffect } from 'react';
import Image from 'next/image';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Label } from '@/components/ui/label';
import { Map, List, Search, ChevronDown, XCircle, Bell, Loader2 } from 'lucide-react';
import { regions, communesByRegion } from '@/lib/locations';
import { categories, subCategories } from '@/lib/categories';
import { cn } from '@/lib/utils';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { StarRating } from '@/components/ui/star-rating';
import { Badge } from '@/components/ui/badge';
import { Separator } from '@/components/ui/separator';
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover';
import Link from 'next/link';
import { useToast } from '@/hooks/use-toast';
import { useFirestore } from '@/firebase';
import type { Class, Venue } from '@/lib/types';
import { collectionGroup, getDocs, query, collection } from 'firebase/firestore';
import MapView from '@/components/map-view';

const levels = ['Todos', 'Básico', 'Intermedio', 'Avanzado', 'Todos los niveles'];
const daysOfWeek = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
const timeSlots = [
    { value: 'all', label: 'Cualquier horario' },
    { value: 'morning', label: 'Mañana (9am - 12pm)' },
    { value: 'afternoon', label: 'Tarde (12pm - 7pm)' },
    { value: 'evening', label: 'Noche (7pm en adelante)' },
];

// Simplified type for what we get from Firestore
type FetchedClass = Omit<Class, 'schedule'> & {
    instructorName?: string; // These will be added later
    instructorAvatar?: string;
    rating?: number;
    reviewCount?: number;
};

export default function SearchClassesPage() {
  const [viewMode, setViewMode] = useState('list');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedRegion, setSelectedRegion] = useState('all');
  const [selectedCommune, setSelectedCommune] = useState('all');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [selectedSubCategory, setSelectedSubCategory] = useState('all');
  const [selectedLevel, setSelectedLevel] = useState('all');
  const [selectedDay, setSelectedDay] = useState('all');
  const [selectedTime, setSelectedTime] = useState('all');
  
  const [allClasses, setAllClasses] = useState<FetchedClass[]>([]);
  const [allVenues, setAllVenues] = useState<Venue[]>([]);
  const [isLoading, setIsLoading] = useState(true);

  const firestore = useFirestore();

  useEffect(() => {
    if (!firestore) return;
    setIsLoading(true);

    const fetchAllData = async () => {
        try {
            // Fetch all venues first
            const venuesQuery = query(collectionGroup(firestore, 'venues'));
            const venuesSnapshot = await getDocs(venuesQuery);
            const venuesData: Venue[] = venuesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Venue));
            setAllVenues(venuesData);

            // Fetch all classes
            const classesQuery = query(collectionGroup(firestore, 'classes'));
            const classesSnapshot = await getDocs(classesQuery);
            const classesData: FetchedClass[] = [];
            classesSnapshot.forEach(doc => {
                const data = doc.data() as Class;
                classesData.push({
                    ...data,
                    id: doc.id,
                    instructorName: 'Instructor', // Placeholder
                    rating: 4.8, // Placeholder
                    reviewCount: 30, // Placeholder
                });
            });
            setAllClasses(classesData);
        } catch (error) {
            console.error("Error fetching data:", error);
        } finally {
            setIsLoading(false);
        }
    };
    
    fetchAllData();

  }, [firestore]);


  const handleRegionChange = (value: string) => {
    setSelectedRegion(value);
    setSelectedCommune('all');
  };
  
  const handleCategoryChange = (value: string) => {
    setSelectedCategory(value);
    setSelectedSubCategory('all');
  };

  const handleClearFilters = () => {
    setSearchTerm('');
    setSelectedRegion('all');
    setSelectedCommune('all');
    setSelectedCategory('all');
    setSelectedSubCategory('all');
    setSelectedLevel('all');
    setSelectedDay('all');
    setSelectedTime('all');
  };

  const filteredClasses = useMemo(() => {
    let classes = allClasses.filter(c => {
      const venue = allVenues.find(v => v.id === c.venueId);
      if (!venue) return false;

      const searchTermMatch = searchTerm === '' || 
        c.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        (c.instructorName && c.instructorName.toLowerCase().includes(searchTerm.toLowerCase()));
      
      const regionMatch = selectedRegion === 'all' || venue.region === selectedRegion;
      const communeMatch = selectedCommune === 'all' || venue.commune === selectedCommune;
      const categoryMatch = selectedCategory === 'all' || c.category === selectedCategory;
      const subCategoryMatch = selectedSubCategory === 'all' || c.subCategory === selectedSubCategory;
      const levelMatch = selectedLevel === 'all' || selectedLevel === 'Todos' || (c.level && c.level === selectedLevel);
      const dayMatch = selectedDay === 'all' || (c.schedules && c.schedules.some(s => s.day === selectedDay));
      
      const timeMatch = selectedTime === 'all' || (c.schedules && c.schedules.some(s => {
        const classHour = parseInt(s.startTime.split(':')[0], 10);
        if (selectedTime === 'morning') return classHour >= 9 && classHour < 12;
        if (selectedTime === 'afternoon') return classHour >= 12 && classHour < 19;
        if (selectedTime === 'evening') return classHour >= 19;
        return false;
      }));

      return searchTermMatch && regionMatch && communeMatch && categoryMatch && subCategoryMatch && levelMatch && dayMatch && timeMatch && c.status === 'Active';
    });

    // Sort classes: available first, then unavailable
    classes.sort((a, b) => {
        const aAvailability = a.availability || 0;
        const bAvailability = b.availability || 0;
        if (aAvailability > 0 && bAvailability === 0) return -1;
        if (aAvailability === 0 && bAvailability > 0) return 1;
        return 0;
    });

    return classes;
  }, [searchTerm, selectedRegion, selectedCommune, selectedCategory, selectedSubCategory, selectedLevel, selectedDay, selectedTime, allClasses, allVenues]);
  
  const getFirstPrice = (pricePlans: Class['pricePlans']) => {
    if (!pricePlans || pricePlans.length === 0) return 0;
    return pricePlans[0].price;
  };
  
  const venueOptions: { value: string; label: string }[] = useMemo(() => {
    return [
      { value: 'all', label: 'Todas las Sedes' },
      ...allVenues.map(v => ({ value: v.id, label: v.name })),
    ];
  }, [allVenues]);

  const ClassCard = ({ cls }: { cls: FetchedClass }) => {
    const { toast } = useToast();
    const isFull = cls.availability === 0;
    const hasPacks = cls.pricePlans && cls.pricePlans.length > 1;

    const handleNotifyClick = () => {
        console.log(`User wants to be notified for class: ${cls.id}`);
        toast({
            title: "¡Notificación Activada!",
            description: `Te avisaremos si se libera un cupo para "${cls.name}".`
        });
    }

    return (
        <Card className={cn("overflow-hidden transition-all hover:shadow-md flex flex-col h-full", isFull && "bg-muted/50 opacity-70")}>
            <div className="relative">
                <Link href={`/search-classes/${cls.id}`} className="block">
                    <Image 
                        src={`https://picsum.photos/seed/${cls.id}/600/400`}
                        alt={cls.name}
                        width={600}
                        height={400}
                        className="aspect-[3/2] w-full object-cover"
                    />
                </Link>
                {isFull && <Badge variant="destructive" className="absolute top-2 left-2">Completo</Badge>}
            </div>
            <CardContent className="p-4 space-y-3 flex flex-col flex-1">
                 <div className="flex items-start justify-between gap-2">
                    <div className="flex-1">
                      <Link href={`/search-classes/${cls.id}`}>
                        <h3 className="font-headline font-semibold text-lg leading-tight">{cls.name}</h3>
                      </Link>
                    </div>
                    <div className="flex items-center gap-1 shrink-0">
                      <p className="font-bold text-lg text-primary">${getFirstPrice(cls.pricePlans).toLocaleString('es-CL')}</p>
                      {hasPacks && (
                        <Popover>
                          <PopoverTrigger asChild>
                            <Button variant="ghost" size="icon" className="h-6 w-6 text-primary hover:bg-primary/10">
                              <ChevronDown className="h-5 w-5" />
                              <span className="sr-only">Ver planes</span>
                            </Button>
                          </PopoverTrigger>
                          <PopoverContent className="w-60">
                            <div className="grid gap-4">
                              <div className="space-y-2">
                                <h4 className="font-medium leading-none">Planes Disponibles</h4>
                                <p className="text-sm text-muted-foreground">
                                  Ahorra comprando un pack de clases.
                                </p>
                              </div>
                              <div className="grid gap-2">
                                {cls.pricePlans.map(plan => (
                                  <div key={plan.name} className="grid grid-cols-2 items-center gap-4 text-sm">
                                    <span>{plan.name}</span>
                                    <span className="font-semibold text-right">${plan.price.toLocaleString('es-CL')}</span>
                                  </div>
                                ))}
                              </div>
                            </div>
                          </PopoverContent>
                        </Popover>
                      )}
                    </div>
                 </div>
                  <div className='flex-1'>
                    <Link href={`/search-classes/${cls.id}`} className="space-y-2">
                      <div className="flex items-center gap-2 text-sm text-muted-foreground">
                          <Avatar className="h-6 w-6">
                              <AvatarImage src={cls.instructorAvatar} alt={cls.instructorName} />
                              <AvatarFallback>{cls.instructorName ? cls.instructorName.charAt(0) : 'I'}</AvatarFallback>
                          </Avatar>
                          <span>{cls.instructorName}</span>
                      </div>
                      <div className="flex items-center gap-2">
                          <StarRating rating={cls.rating || 0} />
                          <span className="text-xs text-muted-foreground">({cls.reviewCount} opiniones)</span>
                      </div>
                    </Link>
                  </div>
                 <Separator />
                 <div className="flex items-center justify-between text-sm text-muted-foreground pt-1">
                    <span>{cls.level}</span>
                    {isFull ? (
                        <Button variant="outline" size="sm" onClick={handleNotifyClick}>
                            <Bell className="mr-2 h-4 w-4" />
                            Notificarme
                        </Button>
                    ) : (
                        <Badge variant={'default'} className="whitespace-nowrap">
                            {`${cls.availability} cupos disponibles`}
                        </Badge>
                    )}
                 </div>
            </CardContent>
        </Card>
    )
  };


  return (
    <div className="flex flex-col gap-8">
      <div>
        <h1 className="font-headline text-3xl font-semibold">Buscar Clases</h1>
        <p className="text-muted-foreground mt-1">Explora, aprende y conéctate con otros instructores.</p>
      </div>

      <Card>
        <CardContent className="p-4">
          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
            <div className="relative md:col-span-2 lg:col-span-3 xl:col-span-4">
              <Input
                placeholder="Buscar por clase o instructor..."
                className="pl-10"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
              <Search className="absolute left-3 top-1/2 h-5 w-5 -translate-y-1/2 text-muted-foreground" />
            </div>

            <div className="grid grid-cols-1 gap-4 md:col-span-2 lg:col-span-3 xl:col-span-4 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
              <div>
                <Label htmlFor="region">Región</Label>
                <Select value={selectedRegion} onValueChange={handleRegionChange}>
                  <SelectTrigger id="region">
                    <SelectValue placeholder="Todas" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todas</SelectItem>
                    {regions.map((r) => (
                      <SelectItem key={r.value} value={r.value}>
                        {r.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="commune">Comuna</Label>
                <Select
                  value={selectedCommune}
                  onValueChange={setSelectedCommune}
                  disabled={selectedRegion === 'all'}
                >
                  <SelectTrigger id="commune">
                    <SelectValue placeholder="Todas" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todas</SelectItem>
                    {selectedRegion &&
                      communesByRegion[selectedRegion]?.map((c) => (
                        <SelectItem key={c.value} value={c.value}>
                          {c.label}
                        </SelectItem>
                      ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="category">Categoría</Label>
                <Select
                  value={selectedCategory}
                  onValueChange={handleCategoryChange}
                >
                  <SelectTrigger id="category">
                    <SelectValue placeholder="Todas" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todas</SelectItem>
                    {categories.map((c) => (
                      <SelectItem key={c.value} value={c.value}>
                        {c.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="subcategory">Estilo</Label>
                <Select
                  value={selectedSubCategory}
                  onValueChange={setSelectedSubCategory}
                  disabled={
                    selectedCategory === 'all' || !subCategories[selectedCategory]
                  }
                >
                  <SelectTrigger id="subcategory">
                    <SelectValue placeholder="Todos" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todos</SelectItem>
                    {selectedCategory &&
                      subCategories[selectedCategory]?.map((s) => (
                        <SelectItem key={s.value} value={s.value}>
                          {s.label}
                        </SelectItem>
                      ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="level">Nivel</Label>
                <Select value={selectedLevel} onValueChange={setSelectedLevel}>
                  <SelectTrigger id="level">
                    <SelectValue placeholder="Todos" />
                  </SelectTrigger>
                  <SelectContent>
                    {levels.map((l) => (
                      <SelectItem key={l} value={l}>
                        {l}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="day">Día de la semana</Label>
                <Select value={selectedDay} onValueChange={setSelectedDay}>
                  <SelectTrigger id="day">
                    <SelectValue placeholder="Todos" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">Todos</SelectItem>
                    {daysOfWeek.map((d) => (
                      <SelectItem key={d} value={d}>
                        {d}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div>
                <Label htmlFor="time">Horario</Label>
                <Select value={selectedTime} onValueChange={setSelectedTime}>
                  <SelectTrigger id="time">
                    <SelectValue placeholder="Cualquier horario" />
                  </SelectTrigger>
                  <SelectContent>
                    {timeSlots.map((t) => (
                      <SelectItem key={t.value} value={t.value}>
                        {t.label}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="flex items-end">
                <Button variant="ghost" onClick={handleClearFilters} className="w-full">
                  <XCircle className="mr-2 h-4 w-4" />
                  Quitar Filtros
                </Button>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
      
      <div className="flex items-center justify-between">
        <p className="text-sm text-muted-foreground">{isLoading ? 'Buscando...' : `${filteredClasses.length} clases encontradas.`}</p>
        <div className="flex items-center gap-2 rounded-md bg-muted p-1">
            <Button variant={viewMode === 'list' ? 'secondary' : 'ghost'} size="sm" onClick={() => setViewMode('list')} className="gap-2">
                <List className="h-4 w-4" />
                Lista
            </Button>
            <Button variant={viewMode === 'map' ? 'secondary' : 'ghost'} size="sm" onClick={() => setViewMode('map')} className="gap-2">
                <Map className="h-4 w-4" />
                Mapa
            </Button>
        </div>
      </div>

      {isLoading ? (
        <div className="flex h-64 items-center justify-center">
            <Loader2 className="h-8 w-8 animate-spin" />
        </div>
      ) : viewMode === 'list' ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
            {filteredClasses.length > 0 ? (
                filteredClasses.map(cls => (
                    <ClassCard key={cls.id} cls={cls} />
                ))
            ) : (
                <div className="md:col-span-2 lg:col-span-3 xl:col-span-4 text-center text-muted-foreground py-16">
                    <p>No se encontraron clases con los filtros actuales.</p>
                </div>
            )}
        </div>
      ) : (
        <MapView classes={filteredClasses} venues={allVenues} />
      )}

    </div>
  );
}
